select *, now()
from {{ source('my_raw_data', 'team') }}


