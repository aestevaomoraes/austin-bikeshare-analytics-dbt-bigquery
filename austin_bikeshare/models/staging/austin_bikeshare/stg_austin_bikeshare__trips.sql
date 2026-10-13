with source as (

    select * from {{ source('austin_bikeshare', 'bikeshare_trips') }}

),

renamed as (

    select
        -- Identificadores
        cast(trip_id as string) as trip_id,
        cast(bike_id as string) as bike_id,
        cast(bike_type as string) as bike_type,

        -- Estações de Origem e Destino
        cast(start_station_id as string) as start_station_id,
        cast(start_station_name as string) as start_station_name,
        cast(end_station_id as string) as end_station_id,
        cast(end_station_name as string) as end_station_name,

        -- Métricas temporais
        cast(start_time as timestamp) as started_at,
        cast(duration_minutes as int64) as duration_minutes,

        -- Tipologia de utilizador
        cast(subscriber_type as string) as subscriber_type

    from source

)

select * from renamed