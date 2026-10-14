with trips as (

    select * from {{ ref('stg_austin_bikeshare__trips') }}

),

enriched as (

    select
        -- Identificadores originais
        trip_id,
        bike_id,
        bike_type,
        start_station_id,
        start_station_name,
        end_station_id,
        end_station_name,
        subscriber_type,

        -- Métricas temporais brutas
        started_at,
        duration_minutes,

        -- Componentes de data/hora (Time Parts)
        extract(year from started_at) as trip_year,
        extract(month from started_at) as trip_month,
        extract(day from started_at) as trip_day,
        extract(hour from started_at) as trip_hour,
        extract(dayofweek from started_at) as trip_day_of_week,

        -- Indicador de Fim de Semana (1 = Domingo, 7 = Sábado no BigQuery)
        case
            when extract(dayofweek from started_at) in (1, 7) then true
            else false
        end as is_weekend,

        -- Classificação do Turno do Dia
        case
            when extract(hour from started_at) between 5 and 11 then 'Manhã'
            when extract(hour from started_at) between 12 and 17 then 'Tarde'
            when extract(hour from started_at) between 18 and 22 then 'Noite'
            else 'Madrugada'
        end as time_of_day,

        -- Classificação de Rota
        case
            when start_station_id = end_station_id then true
            else false
        end as is_round_trip,

        -- Faixas de Duração da Viagem
        case
            when duration_minutes <= 10 then '0-10 min (Curta)'
            when duration_minutes <= 30 then '11-30 min (Média)'
            when duration_minutes <= 60 then '31-60 min (Longa)'
            else 'Mais de 60 min (Prolongada)'
        end as trip_duration_bucket

    from trips

)

select * from enriched