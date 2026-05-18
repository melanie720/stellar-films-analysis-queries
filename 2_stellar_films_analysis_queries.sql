/*
Overview:

Stellar Films Studios
Production & Financial Risk Management Analysis

Problem:
Stellar Films Studios is seeing a trend of "Budget Creep" (movies going over budget)
and inconsistent returns on investment (ROI).

Solution:
My goal is to write queries that support production data analysis and help
to identify combinations of Director, Genre, and Shooting Location that
yield the lowest financial risk and highest profitability.

I will determine the following:
A. The "Efficiency Score" and directors with consistent efficiency.
B. The "Location ROI" (plus heatmap).
C. Risk Analysis: "The Red Flags"
D. Greenlight decisions for producers.
*/

use StellarFilms
go


/*
A. The "Efficiency Score".

Approach:

My goal for the following query was to find directors who consistently deliver under/at budget AND ahead of/directly on schedule.

1. The query finds each director's budget and schedule efficiency scores for each of their movies.
2. Then, to gain insight on which genre(s) each director is most efficient in, I get an average of their efficiency scores separated by genre.
3. This information is contained in a CTE which the following query filters for the directors who have consistently delivered under/at budget 
    and ahead of/directly on schedule, then returns their average budget efficiency by genre and average schedule efficiency by genre.

Efficiency scores here are measured against a baseline of 100%, where actual values match planned values,
    and are calculated as actual / planned.
A lower score is better, showing that resources were conserved.

We find that a couple of directors have been successful at more than one genre -- Kaito Sato & Rina Patel.

We also find that Ava Rodriguez is more efficient than Kaito Sato in Comedy.
*/

with sub as (
    select
        t.person_firstname + ' ' + t.person_lastname as director,
        g.genre_name,
        (f.actual_spend/f.budget_allocated) * 100 as budg_eff_by_film,
        cast(avg((f.actual_spend/f.budget_allocated)  * 100) over (partition by t.person_id, g.genre_name) as decimal(5,2)) as avg_budg_eff_by_genre,
        s.actual_shooting_days - s.planned_shooting_days as sched_var_in_days,
        (cast(s.actual_shooting_days as real)/cast(s.planned_shooting_days as real)) * 100 as sched_eff_by_film,
        cast(avg(cast(s.actual_shooting_days as real)/cast(s.planned_shooting_days as real)  * 100) over (partition by t.person_id, g.genre_name) as decimal(5,2)) as avg_sched_eff_by_genre
            from talent_stats as t
            join productions as p on p.director_id = t.person_id
            join finances as f on f.prod_id = p.prod_id
            join schedules as s on s.prod_id = p.prod_id
            join genres as g on g.genre_id = p.genre_id
)

select director, genre_name, avg_budg_eff_by_genre, avg_sched_eff_by_genre 
    from sub 
    group by director, genre_name, avg_budg_eff_by_genre, avg_sched_eff_by_genre
    having
        sum(case when budg_eff_by_film <= 100 then 1 else 0 end) = count(*) and
        sum(case when sched_eff_by_film <= 100 then 1 else 0 end) = count(*)
        

-- B. The "Location ROI" (plus heatmap).
-- Determining which locations provide the best "Revenue-per-Dollar-Spent" ratio after finding the average production delay in that region.
-- * Heatmap and charts included in repository.

select
    l.location_name, cast(avg(cast(actual_shooting_days as real) - cast(planned_shooting_days as real)) as decimal(5,2)) as avg_prod_delay,
    cast(avg(f.box_office_global/f.actual_spend) as decimal(5,2)) as avg_rev_per_dollar_spent
        from locations as l
        join productions as p on p.primary_location_id = l.location_id
        join schedules as s on s.prod_id = p.prod_id
        join finances as f on f.prod_id = p.prod_id
            group by l.location_name


-- C. Risk Analysis: "The Red Flags".
-- Identifying common traits in "Flops" (movies where box_office_global < (budget + marketing)).
-- Goal is to find the correlation between production delays and final box office performance.

/*

Approach:

1. The CASE statement comes in handy for this query.
    I was able to compare spending and production delay values to predetermined thresholds and from that comparison, assign a specific classification.

Columns Explained:

film_performance:
    A film Success is one where box office earnings are more than the intended total cost: budget plus market spend.
    A film Flop is one where box office earnings are less than the intended total cost.

film_risk:
    A High Risk film is one where the amount of overspend (if any) equals 20% or more of the budget AND where shooting is delayed for 10 or more days.

*/

select
    p.title as film_title, t.person_firstname + ' ' + t.person_lastname as director,
    case
        when (f.budget_allocated + f.marketing_spend) > f.box_office_global then 'Flop'
        else 'Success'
        end as film_performance,
    s.actual_shooting_days - s.planned_shooting_days as shooting_delay,
    s.delay_reason,
    case
        when (f.actual_spend - f.budget_allocated >= f.budget_allocated * 0.20) and
            (s.actual_shooting_days - s.planned_shooting_days > = 10) then 'High Risk'
        else 'Lower Risk'
        end as film_risk
    from productions as p
    left join schedules as s on s.prod_id = p.prod_id
    left join finances as f on f.prod_id = p.prod_id
    left join talent_stats as t on t.person_id = p.director_id
        order by film_performance


-- D. Recommendations for "Greenlight" decisions.

/*
Stored procedure that recommends a "Greenlight" decision to a producer.

Approach:

1. I used Views and CTEs for reusability and readability.

2. I also used the cast(), format(), and string_agg() built-in functions.
    Here, string_agg() is useful when a genre has more than one optimal filming location.
    
3. Window functions, partitioning, aggregate functions, group by, JOINs.


If a user supplies a director and a genre, the procedure provides:

1.	The director’s ROI of each film.
        Column: film_rev_per_dollar_spent
            For the individual film title.
    
2.	The average profitability of that genre.
        Column: avg_profit_for_genre
            For all films produced by StellarFilms of the same genre.

3.	The optimal shooting location for that genre.
        Column: optimal_location_for_genre
            The location that yielded the highest average profit of all hosted StellarFilms of the genre.   
*/


-- drop view if exists genre_optimal_locations_avg_profit;

-- This View shows you each genre along with its optimal filming location and average profit.
create view genre_optimal_locations_avg_profit
as

-- This first CTE takes each film and its genre, filming location, and financial information, then finds the average profit of each genre in each filming location.
-- The average profits are ranked using dense_rank() so there are no skipped rankings (in case we want to see the 2nd highest average profits one day).
-- The highest average profit (rank 1) identifies the optimal filming location.
with genre_location_rankings as (
    select 
        g.genre_id,
        g.genre_name,
        l.location_name, 
        avg(f.box_office_global - (f.actual_spend + f.marketing_spend)) as avg_profit_gen_loc,
        dense_rank() over (partition by g.genre_id order by avg(f.box_office_global - (f.actual_spend + f.marketing_spend)) desc) as profit_ranking
            from locations as l
            join productions as p on p.primary_location_id = l.location_id
            join genres as g on g.genre_id = p.genre_id
            join finances as f on f.prod_id = p.prod_id
                group by g.genre_id, g.genre_name, l.location_name
),
-- This CTE finds the average profit for each genre across all filming locations.
genre_avg_profit as (
    select 
        distinct g.genre_id,
        format(avg(f.box_office_global - (f.actual_spend + f.marketing_spend)) over (partition by g.genre_name), 'C') as Avg_Profit_for_Genre
            from finances as f
            join productions as p on p.prod_id = f.prod_id
            join genres as g on g.genre_id = p.genre_id
)

-- The following query joins the two CTEs by genre, creating a View that returns each genre with its optimal filming location(s) 
    -- and the average profit for each genre across all filming locations.
select 
    l.genre_id, 
    l.genre_name,
    string_agg(l.location_name, ', ') as Optimal_Loc_for_Genre,
    Avg_Profit_for_Genre
        from genre_location_rankings as l
        join genre_avg_profit as p on p.genre_id = l.genre_id
        where profit_ranking = 1
        group by l.genre_id, l.genre_name, p.Avg_Profit_for_Genre;


-- drop view if exists director_film_stats;

-- This view contains each director's revenue-per-dollar-spent for each of their films.
create view director_film_stats
as
select 
    distinct t.person_firstname as director_fn, 
    t.person_lastname as director_ln, 
    p.title as Title, 
    g.genre_name as Genre,
    cast(f.box_office_global/f.actual_spend as decimal(5,2)) as Film_Rev_per_Dollar_Spent
        from talent_stats as t
        right join productions as p on t.person_id = p.director_id
        join genres as g on g.genre_id = p.genre_id
        join finances as f on f.prod_id = p.prod_id;


drop procedure if exists p_greenlight
go 

create procedure p_greenlight (
    @director_firstname varchar(20) = '',
    @director_lastname varchar(20) = '',
    @genre varchar(15) = ''
) as begin    
    -- Checks for invalid combination of provided director first and last name.
    if @director_firstname != '' and @director_lastname != ''
        if not exists (select 1 from talent_stats where person_lastname = @director_lastname and person_firstname = @director_firstname)
        throw 50016, 'Director by that name does not exist.', 1

    -- Both first and last names provided.
    if @director_firstname != '' and @director_lastname != '' begin
        -- Genre found in Director's filmography.
        if exists (select 1 from director_film_stats where Genre = @genre and director_fn = @director_firstname and director_ln = @director_lastname) begin
            select 
                director_fn + ' ' + director_ln as Director,
                Title, Genre, Film_Rev_per_Dollar_Spent, Avg_Profit_for_Genre, Optimal_Loc_for_Genre
                    from director_film_stats
                    join genre_optimal_locations_avg_profit on Genre = genre_name
                    -- Handles genre provided and no genre provided.
                    where (@genre = '' or Genre = @genre) and director_fn = @director_firstname and director_ln = @director_lastname
                    order by Director, Film_Rev_per_Dollar_Spent desc
        end
        -- Genre not found in Director's filmography.
        else begin
            select 
                director_fn + ' ' + director_ln as Director,
                Title, Genre, Film_Rev_per_Dollar_Spent, Avg_Profit_for_Genre, Optimal_Loc_for_Genre
                    from director_film_stats
                    join genre_optimal_locations_avg_profit on Genre = genre_name
                    where director_fn = @director_firstname and director_ln = @director_lastname
                    order by Director, Film_Rev_per_Dollar_Spent desc
        end
    end
    -- First or last name provided.
    else if @director_firstname != '' or @director_lastname != '' begin
        -- Genre found in Director's filmography.
        if exists (select 1 from director_film_stats where Genre = @genre and (director_fn = @director_firstname or director_ln = @director_lastname)) begin
            select 
                director_fn + ' ' + director_ln as Director,
                Title, Genre, Film_Rev_per_Dollar_Spent, Avg_Profit_for_Genre, Optimal_Loc_for_Genre
                    from director_film_stats
                    join genre_optimal_locations_avg_profit on Genre = genre_name
                    -- Handles genre provided and no genre provided.
                    where (@genre = '' or Genre = @genre) and (director_fn = @director_firstname or director_ln = @director_lastname)
                    order by Director, Film_Rev_per_Dollar_Spent desc
        end
        -- Genre not found in Director's filmography.
        else begin
            select 
                director_fn + ' ' + director_ln as Director,
                Title, Genre, Film_Rev_per_Dollar_Spent, Avg_Profit_for_Genre, Optimal_Loc_for_Genre
                    from director_film_stats
                    join genre_optimal_locations_avg_profit on Genre = genre_name
                    where director_fn = @director_firstname or director_ln = @director_lastname
                    order by Director, Film_Rev_per_Dollar_Spent desc
        end
    end
    -- Only genre provided.
    else begin
        select 
            director_fn + ' ' + director_ln as Director,
            Title, Genre, Film_Rev_per_Dollar_Spent, Avg_Profit_for_Genre, Optimal_Loc_for_Genre
                from director_film_stats
                join genre_optimal_locations_avg_profit on Genre = genre_name
                where Genre = @genre
                order by Director, Film_Rev_per_Dollar_Spent desc
    end
end
go

/*
Test it out:

User can provide a director's first name, last name, or both, with or without a genre.

Without a genre, all of the director's films are returned.
With a genre, if present in the director's work, the procedure will filter by that genre;
    if not present, all of the director's films are returned.

User can provide a genre alone and the procedure will return all films / directors of that genre.
*/

-- Example: Ava Rodriguez; Ava has directed many Action movies.
exec p_greenlight @director_lastname = 'Rodriguez'; -- With this example, you can see the string_agg in action.

exec p_greenlight @director_firstname = 'Ava', @genre = 'Action';

-- Example: Rina Patel; Rina has not directed any Horror movies.

exec p_greenlight @director_lastname = 'Patel', @genre = 'Horror';

-- Example: Providing only a genre.

exec p_greenlight @genre = 'Horror';
