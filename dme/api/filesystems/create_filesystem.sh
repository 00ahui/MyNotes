sh ../api_login.sh
sh ../api_post.sh /rest/fileservice/v1/filesystems/customize '{"storage_id":"addf0252-fe7a-11ea-9281-00505684ab7c","pool_raw_id":"1","filesystem_specs":[{"name":"fs2","capacity":1,"count":1,"start_suffix":0}]}'
