# ------------------------------------------------------------------------
# Copyright 2019 WSO2, Inc. (http://wso2.com)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License
# ------------------------------------------------------------------------

#!/bin/bash
echo "Running DB scripts..."

mysql -u CF_DB_USERNAME -pCF_DB_PASSWORD -h CF_DB_HOST -P CF_DB_PORT < /home/wso2user/dbScripts/MySQL/mysql.sql

for userdbscript in /home/wso2user/dbScripts/MySQL/userManager/*.sql
  do
   echo "Executing script: $userdbscript ..."
   mysql -u CF_DB_USERNAME -pCF_DB_PASSWORD -h CF_DB_HOST -P CF_DB_PORT < $userdbscript
 done

for regdbscript in /home/wso2user/dbScripts/MySQL/registry/*.sql
  do
   echo "Executing script: $regdbscript ..."
   mysql -u CF_DB_USERNAME -pCF_DB_PASSWORD -h CF_DB_HOST -P CF_DB_PORT < $regdbscript
 done

for mgtdbscript in /home/wso2user/dbScripts/MySQL/apmgt/*.sql
  do
   echo "Executing script: $mgtdbscript ..."
   mysql -u CF_DB_USERNAME -pCF_DB_PASSWORD -h CF_DB_HOST -P CF_DB_PORT < $mgtdbscript
 done
