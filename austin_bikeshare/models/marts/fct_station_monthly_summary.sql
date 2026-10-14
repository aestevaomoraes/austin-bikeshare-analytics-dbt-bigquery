with trips as (

    select * from {{ ref('fct_trips') }}

),

stations as (

    select * from {{ ref('dim_stations') }}

),

aggregated as (

    select
        trips.start_station_id as station_id,
        coalesce(stations.station_name, trips.start_station_name) as station_name,
        stations.station_status,
        stations.council_district,
        trips.trip_year,
        trips.trip_month,

        -- Métricas de volume e duração
        count(trips.trip_id) as total_trips,
        round(avg(trips.duration_minutes), 2) as avg_duration_minutes,
        sum(trips.duration_minutes) as total_duration_minutes,

        -- Segmentação de uso
        countif(trips.subscriber_type = 'Walk Up') as walk_up_trips,
        countif(trips.is_round_trip) as round_trips,
        countif(trips.is_weekend) as weekend_trips

    from trips
    left join stations
        on trips.start_station_id = stations.station_id

    group by
        1, 2, 3, 4, 5, 6

)

select * from aggregated