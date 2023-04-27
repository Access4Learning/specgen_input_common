# License
> Copyright &copy; Access 4 Learning&trade; Community.  All Rights Reserved
> 
> Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
> 
> [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0 "Apache License, Version 2.0")
> 
> Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

# Summary

This directory holds a few supporting utilities that can support the trouble shooting or debugging of the Open API yaml files that are produced by the artifacts of the parent directory. The utility used is the [redocly client](https://redocly.com/docs/cli). This is a nodes package and hence a [Nodes JS](https://nodejs.org/en) installation is a pre-requisite to run any redocly command listed on this page.
It is suggested to run any redocly command listed on this page from a linux command prompt due to some bugs of the Windows version. If you are using a windows environment then one option to run a linux environment is the windows built in [Windows Subsystem for Linux (WSL)](https://learn.microsoft.com/en-us/windows/wsl/install). 

# Assumptions & Constraints

All sub-sections and commands listed in this Readme.md are based on the following assumptions:
- Nodes JS and redocly client is installed.
- A compete set of yaml files is present for a given data model as outlined in the Readme.md of the parent directory. These yaml files are all in the same directory.
- All commands are run from either a windows command prompt or linux command prompt (recommended) within the same directory where the Open API yaml files reside.

# Redocly for Open API Validation 

This section list a couple of useful redocly commands to run the Open API yaml file validation. The way redocly works has the potential that one or two errors in the Open API or the examples yaml files can produce tens or hundreds of errors or warnings quickly. Running redocly in its basic form may produce a report that is hundreds of lines long and therefore difficult to read. The commands listed below will direct the redocly output to a file called `error_<locale>.log` where the locale is either `IN` for infrastructure or `AU` for Australia etc.

**Linux**
The example command below is for the Infrastructure Data Model (`IN` in the error log file name).

> redocly lint OpenAPI_IN.yaml --max-problems 40000 > >(tee stdout.log) 2> >(tee error_IN.log >&2)

**Windows**
The example command below is for the Infrastructure Data Model (`IN` in the error log file name).

> redocly lint OpenAPI_IN.yaml --max-problems 40000>stdout.log 2>error_IN.log

Note that the windows version of redocly produces an output containing a number of special characters. It makes the resulting error log file difficult to read in a simple text editor. To remove most of these special characters the windows batch file called `cleanErrorOutput.bat` can be called with the error log file as a parameter. This batch file is part of this directory. It will call `reomove.bat` batch file in this directory to 'clean' the error log file.

> cleanErrorOutput.bat error_IN.log

As mentioned in the 'Summary' section there exists a known [bug](https://github.com/Redocly/redocly-cli/issues/329) in the windows version of redocly (as of April 2023 it seems not fixed, yet). One type of validation errors redocly may report are of this nature:

> Example validation errored: **schema with key or id** "...\..." **already exists**. 

This is an error that could be due to the windows bug or it could be a genuine error. You never know... The only way to find the answer is running redocly in a linux environment.


## redocly.yaml File

This is a support file for redocly. It can control many aspects on how redocly works. Details can be found on the redocly page for the `lint` command:
- https://redocly.com/docs/cli/commands/lint/#custom-configuration-file
- https://redocly.com/docs/cli/configuration/

Note that this redocly.yaml file must be copied to the same directory from where the redocly command is run from. 
In context for the Open API validation this redocly.yaml file only contains a list of errors/warning that shall be ignored (turned off). This can be useful to filter certain error types. As mentioned previously, a simple error in the Open API specification may throw an overwhelming number of errors of various types. With the help of this redocly.yaml files some of the errors/warnings can temporarily be turned off, to limit the error count. Once one error type has been fixed the other error types can be turned back on etc.
 


