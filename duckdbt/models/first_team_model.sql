select *
from {{ source('my_raw_data', 'team') }}