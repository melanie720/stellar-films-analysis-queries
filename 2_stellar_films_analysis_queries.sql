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
2. Then, to gain additional insight on genres, we average each directors' efficiency scores 
    in any genre they have directed.
3. All of this information is contained in a subquery that is then filtered for the directors who have always 
    delivered under/at budget and ahead of/directly on schedule, then returns their 
    average budget efficiency and average schedule efficiency by genre.

Efficiency scores here are measured against a baseline of 100%, where actual values match planned values,
    and are calculated as actual / planned.
A lower score is better, showing that resources were conserved.

We find that a couple of directors have been successful at more than one genre -- Kaito Sato & Rina Patel.

We also find that Ava Rodriguez is more efficient than Kaito Sato in Comedy.
*/

select director, genre_name, avg_budg_eff_by_genre, avg_sched_eff_by_genre from (
    select
        t.person_firstname + ' ' + t.person_lastname as director,
        g.genre_name,
        cast((f.actual_spend/f.budget_allocated) * 100 as decimal(5,2)) as budg_eff_by_film,
        cast(avg((f.actual_spend/f.budget_allocated)  * 100) over (partition by t.person_id, g.genre_name) as decimal(5,2)) as avg_budg_eff_by_genre,
        s.actual_shooting_days - s.planned_shooting_days as sched_var_in_days,
        cast((cast(s.actual_shooting_days as real)/cast(s.planned_shooting_days as real)) * 100 as decimal(5,2)) as sched_eff_by_film,
        cast(avg(cast(s.actual_shooting_days as real)/cast(s.planned_shooting_days as real)  * 100) over (partition by t.person_id, g.genre_name) as decimal(5,2)) as avg_sched_eff_by_genre
            from talent_stats as t
            join productions as p on p.director_id = t.person_id
            join finances as f on f.prod_id = p.prod_id
            join schedules as s on s.prod_id = p.prod_id
            join genres as g on g.genre_id = p.genre_id
                group by t.person_firstname, t.person_lastname, t.person_id, g.genre_name, f.actual_spend, f.budget_allocated,
                    s.actual_shooting_days, s.planned_shooting_days
) as sub 
    group by director, genre_name, avg_budg_eff_by_genre, avg_sched_eff_by_genre
    having
        sum(case when budg_eff_by_film <= 100 then 1 else 0 end) = count(director) and
        sum(case when sched_eff_by_film <= 100 then 1 else 0 end) = count(director)
        

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
    A film Success is one where box office earnings are more than the intended total cost, budget plus market spend.
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

1. I used temporary tables to create the necessary behavior.
    There were a couple of checks required throughout the operation that didn't seem to work as one query.
    i.e. Filtering by row rankings; Searching for a provided parameter value in the results before returning.

2. I also used the cast(), format(), and string_agg() built-in functions.
    Here, string_agg() is useful when a genre has more than one optimal filming location.


If a user supplies a director and a genre, the procedure checks:

1.	The director's historical ROI in that genre.
        Column: film_rev_per_dollar_spent
            For the individual film title.
    
2.	The average profitability of that genre.
        Column: avg_profit_for_genre
            For all films produced by StellarFilms of the same genre.

3.	The optimal shooting location for that genre.
        Column: optimal_location_for_genre
            The location that yielded the highest average profit of all hosted StellarFilms of the genre.   
*/

drop procedure if exists p_greenlight
go 

create procedure p_greenlight (
    @director_firstname varchar(20) = null,
    @director_lastname varchar(20) = null,
    @genre varchar(15) = null
) as begin    
    select g.genre_id, l.location_id, l.location_name, 
        avg(f.box_office_global - (f.actual_spend + f.marketing_spend)) as avg_profit_gen_loc,
        dense_rank() over (partition by g.genre_id order by avg(f.box_office_global - (f.actual_spend + f.marketing_spend)) desc) as profit_ranking
            into #genre_location_profit
            from locations as l
            join productions as p on p.primary_location_id = l.location_id
            join genres as g on g.genre_id = p.genre_id
            join finances as f on f.prod_id = p.prod_id
                group by g.genre_id, l.location_id, l.location_name

    select genre_id, location_id, location_name
        into #optimal_location
        from #genre_location_profit
            where profit_ranking = 1

    select distinct t.person_firstname + ' ' + t.person_lastname as director, p.title, g.genre_name,
        cast(f.box_office_global/f.actual_spend as decimal(5,2)) as film_rev_per_dollar_spent,
        format((select distinct avg(f.box_office_global - (f.actual_spend + f.marketing_spend)) over (partition by g.genre_name)
            from finances as f
            join productions as p2 on p2.prod_id = f.prod_id
            join genres as g on g.genre_id = p.genre_id
                where p2.genre_id = p.genre_id
        ), 'C') as avg_profit_for_genre,
        string_agg(o.location_name, ', ') as optimal_loc_for_genre
            into #director_genre_stats
            from talent_stats as t
            right join productions as p on t.person_id = p.director_id
            join genres as g on g.genre_id = p.genre_id
            join finances as f on f.prod_id = p.prod_id
            join #optimal_location as o on o.genre_id = p.genre_id
                where t.person_firstname = @director_firstname or t.person_lastname = @director_lastname
                group by t.person_firstname, t.person_lastname, p.title, g.genre_name, 
                    f.box_office_global, f.actual_spend, p.genre_id

    if exists (select 1 from #director_genre_stats where genre_name = @genre) begin
        select * from #director_genre_stats where genre_name = @genre
    end
    else begin
        select * from #director_genre_stats order by genre_name
    end

    drop table #genre_location_profit;
    drop table #optimal_location;
    drop table #director_genre_stats;
end
go

/*
Test it out:

User can provide a director's first name, last name, or both, with or without a genre.

Without a genre, all of the director's films are returned.
With a genre, if present in the director's work, the procedure will filter by that genre;
    if not present, all of the director's films are returned.
*/

-- Example: Ava Rodriguez; Ava has directed many Action movies.
exec p_greenlight @director_lastname = 'Rodriguez'; -- With this example, you can see the string_agg in action.

exec p_greenlight @director_firstname = 'Ava', @genre = 'Action';

-- Example: Rina Patel; Rina has not directed any Horror movies.
exec p_greenlight @director_lastname = 'Patel', @genre = 'Horror';