+++
author = "Robert Fletcher"
date = 2020-04-24T16:45:46Z
description = ""
draft = false
thumbnail = "/images/elasticsearch-overview.jpg"
slug = "elasitic-rbac-with-ldap"
title = "Elasitic RBAC with LDAP"

+++


This document wuill go through how to setup rbac with ldap and hpow to extrac varibles from the ldap user to be used to perform specific quiries on a index to restic data based on a number of key fields and a set of custom logic where by a user must have all values of certain fields and have at lest 1 of another field

## Setup Elastic cluster
This requires a elasticsearch cluster to have xpack securirty and a platium licence in order to talk to a ldap server.

The following snippted is the required config for a elasticsearch to talk to a ldap server. 
```
xpack:
  security:
    enabled: true
    authc:
      realms:
        ldap:
          ldap1:
            order: 0
            url: "ldap://35.189.97.160:389"
            bind_dn: "cn=admin,dc=abac-example,dc=com"
            metadata: [cn, sn, postalCode]
            user_search:
              base_dn: "ou=Users,dc=abac-example,dc=com"
              filter: "(cn={0})"
            group_search:
              base_dn: "dc=abac-example,dc=com"
              user_attribute: "uid"
              filter: "memberUid={0}"
            #files:
            #  role_mapping: "ES_PATH_CONF/role_mapping.yml"
            unmapped_groups_as_roles: false
        native:
          native1:
            order: 1
```
__Of Note:__ By default elastic will store the user dn and the groups the user is in the metadata but to map additional fields you will need to populate the `metadata` field

Once the cluster has started you will need to setup the default elastic users password in order for you to interact with elasticsearch
`./bin/elasticsearch-setup-passwords interactive`

You will also need to set up the ldap bind user password. 
`./bin/elasticsearch-keystore add xpack.security.authc.realms.ldap.ldap1.secure_bind_password`

You should now be able to access elasticsearch via postman or curl using basic auth

## Verify
You can check that you log in and what the meta data is via the `/_security/_authenticate` api
```
curl -X GET \
  http://192.168.0.233:9200/_security/_authenticate \
  -H 'Authorization: Basic YWJhY3VzZXI6dGVzdA==' 
```
Which will return a response:
```
{
    "username": "abacuser",
    "roles": [
        "kibana_user",
        "test_abac_policy"
    ],
    "full_name": null,
    "email": null,
    "metadata": {
        "ldap_dn": "cn=abacuser,ou=Users,dc=abac-example,dc=com",
        "ldap_groups": [
            "cn=reader,ou=Groups,dc=abac-example,dc=com",
            "cn=project_b,ou=projects,dc=abac-example,dc=com",
            "cn=managers,ou=job-group,dc=abac-example,dc=com"
        ],
        "postalCode": "UK",
        "cn": "abacuser",
        "sn": "user"
    },
    "enabled": true,
    "authentication_realm": {
        "name": "ldap1",
        "type": "ldap"
    },
    "lookup_realm": {
        "name": "ldap1",
        "type": "ldap"
    }
}
```
As you can see the addition metadata fields have now been populated

## Setup index templates
The first thing is to set up the index template for the security settings
```
curl -X PUT \
  http://192.168.0.233:9200/_template/abac-template \
  -H 'Content-Type: application/json' \
  -H 'Postman-Token: 14b445a6-9498-4587-81c4-c5fe78eedbbf' \
  -H 'cache-control: no-cache' \
  -d '{
  "index_patterns": [
    "abac-*"
  ],
  "settings": {
    "number_of_shards": 1
  },
  "mappings": {
    "properties": {
      "security.sensitivity": {
        "type": "keyword"
      },
      "security.department": {
        "type": "keyword"
      },
      "security.country": {
        "type": "keyword"
      },
      "security.job-group": {
        "type": "keyword"
      },
      "security.project": {
        "type": "keyword"
      }
    }
  }
}
'
```
The next thing to define is the ingest pipeline. This is a simple script writting in elastics perfered scripting language painless. 
The script does a simple but very important function it stores the number of atributes in projects array and store that in a new feild

This script gets applied to every new document that gets ingested into the index. The result of this feild is needed for the query template that will be discussed later in this document.
```
curl -X PUT \
  http://192.168.0.233:9200/_ingest/pipeline/count_projects \
  -H 'Content-Type: application/json' \
  -H 'Postman-Token: 4e5619bc-e65a-4769-b75a-14cdf07cac2a' \
  -H 'cache-control: no-cache' \
  -d '{
  "processors": [
    {
      "script": {
        "lang": "painless",
        "source": " ArrayList projects = ctx['\''security'\'']['\''project'\'']; ctx['\''security'\'']['\''project-count'\''] = projects.length"
      }
    }
  ]
}
'
```

## Setup Query templates
Now that we have the method to index the data and add the required transformations we can define the core logic the role base filtering based on feilds in a document. 
This is done by applying a query template for all queries that get executed on a index. The query that has been formated can be found below. 

The query finds documents based on the following critira:

- First the user must have one of the security.countries (Due to a limitation with the chosen user schema the closest feild to courties was postalCode)
- Second the user be in a minimum of one of the groups listed in the security.job-group
- Finally the user must be in __all__ of the groups listed in security.project
  
The paramaters that are used for the above searches are passed trough using mustash templating from tuser context metadata feild (_user.metadata)
To make the final __AND__ search work we use the term_set query and use the `security.project-count` feild (which was set by the painless script above) for the `minimum_should_match_field`. Since this feild is caluculated automatically we can guarnetee that the terms listed mush match all that are in the document 
```
{
   "bool":{
      "must":[
         {
            "match":{
               "security.country":"{{_user.metadata.postalCode}}"
            }
         },
         {
            "terms":{
               "security.job-group":{{#toJson}}_user.metadata.ldap_groups{{/toJson}}
            }
         }
      ],
      "filter":[
         {
            "terms_set":{
               "security.project":{
                  "terms":{{#toJson}}_user.metadata.ldap_groups{{/toJson}},
                  "minimum_should_match_field":"security.project-count"
               }
            }
         }
      ]
   }
}
```
To create the query template you can run the below command. This will create a new role that will allow only read operations on the `abac-fixed` index and for all queries on that index will run the above query.


```
{ 
    "indices": [{
        "names": ["abac-fixed"],
        "privileges": ["read"],
        "query": {
            "template": {
                "source": "{\"bool\":{\"must\":[{\"match\":{\"security.country\":\"{{_user.metadata.postalCode}}\"}},{\"terms\":{\"security.job-group\":{{#toJson}}_user.metadata.ldap_groups{{/toJson}}}}],\"filter\":[{\"terms_set\":{\"security.project\":{\"terms\":{{#toJson}}_user.metadata.ldap_groups{{/toJson}},\"minimum_should_match_field\":\"security.project-count\"}}}]}}"
            }
        }
    }]
}
```
## Setup Role mappings

Now that we have a role to perform the query. We need to map this role to a user who is in a particular group. 
This is done by defining a role mapping, this cab be done in 2 ways. One is by defining a static role mapping file on the cluster or the perfered way is to use the api

```
curl -X POST \
  http://192.168.0.233:9200/_security/role_mapping/abac-users \
  -H 'Content-Type: application/json' \
  -H 'Postman-Token: 03a17ae7-2dbd-41d1-b1bc-c992c79a6cd2' \
  -H 'cache-control: no-cache' \
  -d '{
  "roles" : ["test_abac_policy" ,"kibana_user" ],
  "rules" : { "field" : {
    "groups" : "cn=reader,ou=Groups,dc=abac-example,dc=com" 
  } },
  "enabled": true
}'
```
We should now have a user who can execute quries on the abac index and also log into kibana

## Example
The below example is based off the work Matt from elastic worked on.  The plan is to load data into the abac-test index so you can see the data without any transformations once we have all the data we will reindex it into the new index appling the ingest pipleine to perfrom the transformation and finally run searches on it as the normal user

### Load data
The following commands should be run as a admin user such as the elastic super user that was set up and the begining of this document

```
curl -X PUT \
  'http://{{elastic_url}}/abac-test/_doc/non-sensitive-uk' \
  -H 'Content-Type: application/json' \
  -H 'Postman-Token: 0a69a554-9fc1-46df-806e-248f31db833c' \
  -H 'cache-control: no-cache' \
  -d '{
  "content": "This is a test document",
  "security": {
    "sensitivity" : "none",
    "department" : ["Insurance","Retail"],
    "country" : ["UK"],
    "job-group" : ["managers", "CEO", "CTO", "datascience"],
    "project" : ["EDW","DataAnalytics"]
  }
}
'

curl -X PUT \
  'http://{{elastic_url}}/abac-test/_doc/parsonal-data' \
  -H 'Content-Type: application/json' \
  -H 'Postman-Token: f99f6425-1fe8-46ea-92a6-f2067ed38c68' \
  -H 'cache-control: no-cache' \
  -d '{
  "content": "This is a personally sensitive document related to a company restructuring",
  "security": {
    "sensitivity" : "personal",
    "department" : ["HR"],
    "country" : ["UK", "Germany", "France"],
    "job-group" : ["managers", "CEO", "CTO", "hr-administrator"],
    "project" : ["restructuring","EDW"]
  }
}'

curl -X PUT \
  'http://{{elastic_url}}/abac-test/_doc/non-sensitive-uk-ldap' \
  -H 'Content-Type: application/json' \
  -H 'Postman-Token: 23fa80f0-acd7-47ea-ad39-c4f5a33aab57' \
  -H 'cache-control: no-cache' \
  -d '{
  "content": "This is a ldap test document",
  "security": {
    "sensitivity" : "none",
    "department" : ["Insurance","Retail"],
    "country" : ["UK"],
    "job-group" : ["managers", "CEO", "CTO", "datascience"],
    "project" : ["cn=project_b,ou=projects,dc=abac-example,dc=com"]
  }
}
'

curl -X PUT \
  'http://{{elastic_url}}/abac-test/_doc/non-sensitive-uk-ldap-test-1' \
  -H 'Content-Type: application/json' \
  -H 'Postman-Token: d0f40471-bd64-4f33-aff6-d72da02df5b1' \
  -H 'cache-control: no-cache' \
  -d '{
  "content": "This is a ldap test document with projects",
  "security": {
    "sensitivity" : "none",
    "department" : ["Insurance","Retail"],
    "country" : ["UK"],
    "job-group" : ["managers", "CEO", "CTO", "datascience"],
    "project" : ["cn=project_b,ou=projects,dc=abac-example,dc=com"]
  }
}
'

curl -X PUT \
  'http://{{elastic_url}}/abac-test/_doc/non-sensitive-uk-ldap-test-2' \
  -H 'Content-Type: application/json' \
  -H 'Postman-Token: 35cd865c-23b4-4ca9-988e-3e6bb04903a5' \
  -H 'cache-control: no-cache' \
  -d '{
  "content": "This is a ldap test document with projects",
  "security": {
    "sensitivity" : "none",
    "department" : ["Insurance","Retail"],
    "country" : ["UK"],
    "job-group" : ["managers", "CEO", "CTO", "datascience"],
    "project" : [
    	"cn=project_a,ou=projects,dc=abac-example,dc=com",
    	"cn=project_c,ou=projects,dc=abac-example,dc=com"
    ]
  }
}
'

curl -X PUT \
  'http://{{elastic_url}}/abac-test/_doc/non-sensitive-uk-ldap-test-3' \
  -H 'Content-Type: application/json' \
  -H 'Postman-Token: 0e82d759-2345-425c-9776-e26fee977bfc' \
  -H 'cache-control: no-cache' \
  -d '{
  "content": "This is a ldap test document with projects",
  "security": {
    "sensitivity" : "none",
    "department" : ["Insurance","Retail"],
    "country" : ["UK"],
    "job-group" : [
    	"cn=managers,ou=job-group,dc=abac-example,dc=com",
    	"cn=cxo,ou=job-group,dc=abac-example,dc=com",
    	"cn=hr-admin,ou=job-group,dc=abac-example,dc=com"
    	],
    "project" : [
    	"cn=project_b,ou=projects,dc=abac-example,dc=com"
    ]
  }
}
'
```
Run a seach. you should see 6 douments return
```
curl -X GET \
  'http://{{elastic_url}}/abac-test/_search' \
  -H 'Postman-Token: 4feae984-db16-44fc-8604-e67d7986e96a' \
  -H 'cache-control: no-cache'
```

### Reindex data
We will now reindex the data into the new index appling the transfomations to caluate the  `security.project-count`

```
curl -X POST \
  http://192.168.0.233:9200/_reindex \
  -H 'Content-Type: application/json' \
  -H 'Postman-Token: 2251ea48-1c3e-40e7-b327-07a0768a268a' \
  -H 'cache-control: no-cache' \
  -d '{
  "source": {
    "index": "abac-test"
  },
  "dest": {
    "index": "abac-fixed",
    "pipeline": "count_projects"
  }
  
}'
```
If you now run a search as the admin user on this new index you will see the same 6 documents but now there should be a new feild `security.project-count` that will the length of the projects array. 

### Search
As a normal user using Matts LDAP server we will use the abacuser that has the following meta data (from `/_security/_authenticate` api)
```
{
    "username": "abacuser",
    "roles": [
        "kibana_user",
        "test_abac_policy"
    ],
    "full_name": null,
    "email": null,
    "metadata": {
        "ldap_dn": "cn=abacuser,ou=Users,dc=abac-example,dc=com",
        "ldap_groups": [
            "cn=reader,ou=Groups,dc=abac-example,dc=com",
            "cn=project_b,ou=projects,dc=abac-example,dc=com",
            "cn=managers,ou=job-group,dc=abac-example,dc=com"
        ],
        "postalCode": "UK",
        "cn": "abacuser",
        "sn": "user"
    },
    "enabled": true,
    "authentication_realm": {
        "name": "ldap1",
        "type": "ldap"
    },
    "lookup_realm": {
        "name": "ldap1",
        "type": "ldap"
    }
}
```

If we now run the same search as before as this new user you will see only 2 documents
```
{
    "took": 10,
    "timed_out": false,
    "_shards": {
        "total": 1,
        "successful": 1,
        "skipped": 0,
        "failed": 0
    },
    "hits": {
        "total": {
            "value": 2,
            "relation": "eq"
        },
        "max_score": 1.0,
        "hits": [
            {
                "_index": "abac-fixed",
                "_type": "_doc",
                "_id": "non-sensitive-uk-ldap",
                "_score": 1.0,
                "_source": {
                    "security": {
                        "country": [
                            "UK"
                        ],
                        "project-count": 1,
                        "job-group": [
                            "cn=managers,ou=job-group,dc=abac-example,dc=com",
                            "CEO",
                            "CTO",
                            "datascience"
                        ],
                        "project": [
                            "cn=project_b,ou=projects,dc=abac-example,dc=com"
                        ],
                        "sensitivity": "none",
                        "department": [
                            "Insurance",
                            "Retail"
                        ]
                    },
                    "content": "This is a ldap test document with projects"
                }
            },
            {
                "_index": "abac-fixed",
                "_type": "_doc",
                "_id": "non-sensitive-uk-ldap-test-3",
                "_score": 1.0,
                "_source": {
                    "security": {
                        "country": [
                            "UK"
                        ],
                        "project-count": 1,
                        "job-group": [
                            "cn=managers,ou=job-group,dc=abac-example,dc=com",
                            "cn=cxo,ou=job-group,dc=abac-example,dc=com",
                            "cn=hr-admin,ou=job-group,dc=abac-example,dc=com"
                        ],
                        "project": [
                            "cn=project_b,ou=projects,dc=abac-example,dc=com"
                        ],
                        "sensitivity": "none",
                        "department": [
                            "Insurance",
                            "Retail"
                        ]
                    },
                    "content": "This is a ldap test document with projects"
                }
            }
        ]
    }
}
```
This search will only return projects that __only__ contain `cn=project_b,ou=projects,dc=abac-example,dc=com` have the country that includes UK and a job that includes  `cn=managers,ou=job-group,dc=abac-example,dc=com` as they are the only groups the user is in.

---

## Future work

There still further investigations that need to happen. First is the work on the sensitivity field where there are some idea's about using a scoring system. 
The other limitation is that the projects jobs need the group full DN rather then just the group name. There needs some work to see if we can extract that somehow.
The final bit of investigation will be to see if we can hook into some nonstandard lookup service.



