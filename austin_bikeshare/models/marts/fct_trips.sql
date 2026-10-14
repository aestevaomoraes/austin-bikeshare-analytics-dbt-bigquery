with trips as (

    select * from {{ ref('int_trips_enriched') }}

),

final as (

    select
        trip_id,
        bike_id,
        bike_type,
        subscriber_type,

        -- Chaves de dimensão (Foreign Keys)
        start_station_id,
        start_station_name,
        end_station_id,
        end_station_name,

        -- Métricas e tempos
        started_at,
        duration_minutes,
        trip_year,
        trip_month,
        trip_day,
        trip_hour,
        trip_day_of_week,
        is_weekend,
        time_of_day,
        is_round_trip,
        trip_duration_bucket

    from trips

)

select * from final