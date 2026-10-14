with stations as (

    select * from {{ ref('stg_austin_bikeshare__stations') }}

),

final as (

    select
        station_id,
        station_name,
        station_status,
        address,
        coalesce(total_docks, 0) as total_docks,
        power_type,
        property_type,
        council_district,
        updated_at

    from stations

)

select * from final