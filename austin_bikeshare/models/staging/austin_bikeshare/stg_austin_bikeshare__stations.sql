with source as (

    select * from {{ source('austin_bikeshare', 'bikeshare_stations') }}

),

renamed as (

    select
        -- Identificadores
        cast(station_id as string) as station_id,
        cast(name as string) as station_name,
        cast(status as string) as station_status,

        -- Propriedades e Infraestrutura
        cast(address as string) as address,
        cast(number_of_docks as int64) as total_docks,
        cast(power_type as string) as power_type,
        cast(property_type as string) as property_type,
        cast(council_district as int64) as council_district,

        -- Metadados de Auditoria
        cast(modified_date as timestamp) as updated_at

    from source

)

select * from renamed