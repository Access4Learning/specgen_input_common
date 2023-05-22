# License
> Copyright &copy; Access 4 Learning&trade; Community.  All Rights Reserved
> 
> Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
> 
> [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0 "Apache License, Version 2.0")
> 
> Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

# Summary

This repository is a collection of various files that are used by SpecGen to produce the Open API specification files for
various data models. Each data model has its specific input XML file that is produced by SpecGen. Generally that input XML has the name SIF_DataModel.input-\<version\>.xml. This file is not part of this repository since it will be generated each time the SpecGen process is run. To produce the Open API specification this input XML file will be processed by various XSLT Transformation. Each XSLT transformation will produce a specific component of the final Open API specification. It is important to note that the input XML file also contains XML examples for various SIF Object. These examples will be translated to JSON as part of the XSLT processing. 

This repository has the following files each of which will be detailed in sections below:

 **XSLT Files**
- dmToOpenAPI.xsl
- dmToJsonSchema.xsl
- dmToExamples.xsl
- xmlToJson-goessner.xslt
- xmlToJson.xsl (will produce sif2jsonspecgen.xslt which is local specific)

**yaml Template Files (require pre-processing)**
- commonDefs.template.yaml
- infraPaths.temaplate.yaml

**Static yaml Files**
- jsonSchema\_OpenAPI3.0\_Create_IN.yaml
- jsonSchema\_OpenAPI3.0\_Update_IN.yaml
- jsonSchema\_OpenAPI3.1\_Create_IN.yaml
- jsonSchema\_OpenAPI3.1\_Update_IN.yaml

# XSLT file Usage

This section outlines the usage of each XSLT file that is part of this repository. Some XSLT files need to be called with the input XML file, while others are supporting XSLT files that are called from within a XSLT file.

### dmToOpenAPI.xsl

This XSLT file is responsible to produce the top-level Open API yaml file. It will have references to a number of other yaml files that are produced with the remaining XSLT processes listed in this section.

**Input**
Locale specific input XML file that was produced by the SpecGen process (e.g. `SIF_DataModel.infra.input-3.5.xml`).

**Input Parameters**
This XSLT file supports a number of input parameters, all of type string, to drive its output and behaviour. These are listed below
| Parameter Name                | Required | Valid Values | Default    | Description |
| :---------------------------- | :------- | :----------- | :--------- | :---------- |
| sifVersion                    | Yes      | -            | -          | Example: 3.5 |
| sifLocale                     | Yes      | -            | -          | Example `IN` for Infrastructure or `AU` for Australia |
| sifObjectList                 | No       | -            | Empty List | If not provided or empty then the OpenAPI yaml for all objects in the input file will be produced. |
| sifObjectGroupList            | No       | -            | Empty List | If not provided or empty then the OpenAPI yaml for all objects of all groups in the input file will be produced. |
| includeAllHeaders             | No       | true, false  | false      | true: All HTTP headers will be listed. false: Only main HTTP headers will be listed.|
| includeAdminDirectives        | No       | true, false  | false      | true: Admin Directive end-points will be included. false: Admin Directive end-points will be omitted. |
| omitVersionInExamplesFileName | No       | true, false  | false      | true: Version number will be omitted in the example yaml file. false:  The version number will be included in the name of the example yaml files.|
| openAPI30                     | No       | true, false  | true       | true: Produce Open API 3.0 yaml files. false: Produce Open API 3.1 yaml files |

**Output**
The locale specific top-level Open API yaml file. It will have a prefix of OpenAPI optionally followed by the locale (e.g. `OpenAPI_IN.yaml` for Infrastructure or `OpenAPI_AU.yaml` for the Australian Datamodel).

### dmToJsonSchema.xsl

This XSLT file is responsible for producing the various data model schemas for a given SIF specification. These schemas are referenced from the top-level Open API yaml file. The various input parameters are of importance to drive the specific schemas. These can be more or less strict in terms of mandatory elements. The schemas for _create_ end-points are more strict than the schemas for _update_ end-points. Generally this XSLT needs to be called twice with a different set of input parameters, so that the _create_ and _update_ schemas are produced because the top-level Open API yaml has references to both schemas.

**Input**
Locale specific input XML file that was produced by the SpecGen process (e.g. `SIF_DataModel.infra.input-3.5.xml`).

**Input Parameters**
This XSLT file supports a number of input parameters, all of type string, to drive its output and behaviour. These are listed below
| Parameter Name  | Required | Valid Values       | Default  | Description |
| :-------------- | :------- | :----------------- | :------- | :---------- |
| sifVersion      | Yes      | -                  | -        | Example: 3.5 |
| sifLocale       | Yes      | -                  | -        | Example `IN` for Infrastructure or `AU` for Australia |
| openAPI30       | No       | true, false        | true     | true: Produce schemas yaml files for Open API 3.0. false: Produce schemas yaml files for Open API 3.1 |
| mandatoryFields | No       | required, optional | required | required: Will produce the strict schema files for _create_ end-points. optional: Will produce the schema files for _update_ end-points |
| enumCount       | No       | -                  | 12       | This number indicates the maximum number of listed options for enumeration style values. |

**Output**
The locale specific schema yaml files for _create_ and/or _update_ end-points. The final name of the output file depends on the input parameters but generally follows the naming structure of `jsonSchema_OpenAPI<openAPIVersion>_Create_<sifLocale>.yaml` or `jsonSchema_OpenAPI<openAPIVersion>_Update_<sifLocale>.yaml`.

### dmToExamples.xsl

This XSLT file is responsible for producing the example yaml files in various formats such as PESC JSON, Goessner JSON and XML. The examples are sourced from the locale specific input XML file. The examples in the input XML file are in XML format and therefore must be transformed to potentially two JSON formats. To do so, this XSLT transformation file includes the xmlToJson-goessner.xslt XSLT file to produce Goessner JSON examples and the sif2jsonspecgen.xslt XSLT file to produce the PESC JSON examples.

**Input**
Locale specific input XML file that was produced by the SpecGen process (e.g. `SIF_DataModel.infra.input-3.5.xml`).

**Input Parameters**
This XSLT file supports a number of input parameters, all of type string, to drive its output and behaviour. These are listed below
| Parameter Name | Required | Valid Values | Default   | Description |
| :------------- | :------- | :----------- | :-------- | :---------- |
| sifVersion     | Yes      | -            | -         | Example: 3.5 |
| sifLocale      | Yes      | -            | -         | Example `IN` for Infrastructure or `AU` for Australia |
| sifObjectList  | No       | -            | Empty List| If not provided or empty then the examples for all objects in the input file will be produced. |

**Output**
The example yaml file that holds the examples listed in the input XML file in various formats such as Goessner JSON, PESC JSON and XML. The final name of the output file depends on the input parameters but generally follows the naming structure of `examples_<sifLocale>_<sifVersion>.yaml`. Note that the \<sifVersion\> is only required if the `omitVersionInExamplesFileName` parameter was set to `false` in for the top-level Open API yaml file generation.

### xmlToJson-goessner.xslt

This XSLT file is included by the `dmToExamples.xsl` XSLT to produce the Goessner JSON based on the XML examples. It convert XML to JSON based on the [Goessner transformation rules](https://www.xml.com/pub/a/2006/05/31/converting-between-xml-and-json.html).

### xmlToJson.xsl

This file is required by SpecGen and is used to produce a file called `sif2jsonspecgen.xslt`. This resulting XSLT file is included by the `dmToExamples.xsl` XSLT to produce the PESC JSON based on the XML examples. It convert XML to JSON based on the [PESC transformation rules](https://nebula.wsimg.com/d0589a95b719d81e77b5d20dffba7f02?AccessKeyId=4CF7FAE11697F99C9E6B&disposition=0&alloworigin=1).
It is important to note that the `sif2jsonspecgen.xslt` is different for each locale data model because the rules in this XSLT files are data model 'schema-aware'.

# yaml Temaplate Files

The files described in this section are yaml templates and will require pre-processing (hence the template nature of these yaml files). The pre-processing is required to make them valid yaml for either Open API 3.0 or Open API 3.1. The pre-processing of both files consists of replacing certain tags in the file and name the resulting file correctly. The specifics for each yaml file template and the required pre-processing steps are outlined in the following sections.

## commonDefs.template.yaml

This yaml template file holds common definitions, such header names, error examples etc. The top level Open API yaml file has many references to this file. Hence this file must be provided as part of a complete Open API specification for any data model. However to make this a valid yaml file it must be pre-processed. The pre-processing consists of replacing a few tags with the correct values as well as naming the final file correctly. The final file name must be called `commonDefs.yaml`. The two sections below describe with what values the tags in the commonDefs.template.yaml need to be replaced with. It largely depends whether the Open API specification is produced for Open API 3.0 or 3.1.

#### Open API 3.0

To make the `commonDefs.yaml` valid for Open API 3.0 the tags in the `commonDefs.temaplate.yaml` need to be replaced with the following values:
- Replace the `#{OpenAPIVersion}` tag with `3.0`.
- Replace the `#{CommenOutExmpl}` tag with `#` or remove that line altogether.
- Replace the `#{CommenOutHdr}` tag with empty string if the top level Open API was produced with the parameter `includeAllHeaders=true`, otherwise replace the tag with `#` or remove that line altogether.

#### Open API 3.1

To make the `commonDefs.yaml` valid for Open API 3.1 the tags in the `commonDefs.temaplate.yaml` need to be replaced with the following values:
- Replace the `#{OpenAPIVersion}` tag with `3.1`.
- Replace the `#{CommenOutExmpl}` tag with an empty string.
- Replace the `#{CommenOutHdr}` tag with empty string if the top level Open API was produced with the parameter `includeAllHeaders=true`, otherwise replace the tag with `#` or remove that line altogether.

## infraPaths.template.yaml

This yaml file is a template and is only required for the SIF Infrastructure Open API specification. There are two tags in this template that need to be replaced during the pre-processing step. The resulting file must be named `infraPaths.yaml` to ensure that the references in the top-level Open API yaml file resolve properly.

#### Open API 3.0

To make the `infraPaths.yaml` valid for Open API 3.0 the tags in the `infraPaths.temaplate.yaml` need to be replaced with the following values:
- Replace the `#{OpenAPIVersion}` tag with `3.0`.
- Replace the `#{CommenOutExmpl}` tag with `#` or remove that line altogether.

#### Open API 3.1

To make the `infraPaths.yaml` valid for Open API 3.1 the tags in the `infraPaths.temaplate.yaml` need to be replaced with the following values:
- Replace the `#{OpenAPIVersion}` tag with `3.1`.
- Replace the `#{CommenOutExmpl}` tag with an empty string.


# Static yaml Files

Not all artifacts are produced via XSLTs or the yaml template files. There are a number of static yaml files that are required to provide a complete Open API specification of a SIF data model. These static yaml files are referenced from the top-level Open API yaml file that is produced by the `dmToOpenAPI.xsl` as well as the `commonDefs.yaml` file. Depending whether the Open API specification for version 3.0 or 3.1 is produced, the respective set of static yaml files must be provided. 

#### Open API 3.0

To complete a locale specific Open API specification add the following static yaml files to the set of generated yaml files:
- jsonSchema\_OpenAPI3.0\_Create_IN.yaml
- jsonSchema\_OpenAPI3.0\_Update_IN.yaml

#### Open API 3.1

To complete a locale specific Open API specification add the following static yaml files to the set of generated yaml files:
- jsonSchema\_OpenAPI3.1\_Create_IN.yaml
- jsonSchema\_OpenAPI3.1\_Update_IN.yaml


# Steps to produce a complete Open API Specification

The steps below are required to produce a complete set of yaml files for the Open API specification of a specific SIF data model. These steps consists of producing a set of yaml files through the various XSLT transformations and then add the required static yaml files. The locale specific input XML file that was produced by the SpecGen process is required for the XSLT transformations.

1) Produce the top-level Open API yaml file with the `dmToOpenAPI.xsl`. This creates the `OpenAPI.yaml` file.
2) Produce the 'Create' schema yaml file with the `dmToJsonSchema.xsl`. This creates the `jsonSchema_OpenAPIxx_Create_yy.yaml` file.
3) Produce the 'Update' schema yaml file with the `dmToJsonSchema.xsl`. This creates the `jsonSchema_OpenAPIxx_Update_yy.yaml` file.
4) Produce the Example yaml file with the `dmToExamples.xsl`. This creates the `examples.yaml` file.
5) Pre-process the `commonDefs.temaplate.yaml` and add the resulting `commonDefs.yaml` file.
6) One of the sub-steps is required depending whether the infrastructure or a locale data model Open API is produced: 
   - If the Open API yaml files for the Infrastructure are produced, pre-process the `infraPaths.temaplate.yaml` and add the resulting `infraPaths.yaml` file.
   - If the Open API yaml files are produced for a locale (e.g. AU, NA) then step 2 and step 3 should be repeated with the infrastructure input XML file. This is required because the `commonDefs.yaml` holds references to infrastructure data models such as the error message structure. The resulting `jsonSchema_OpenAPIxx_Create_IN.yaml` and `jsonSchema_OpenAPIxx_Update_IN.yaml` must be added to complete the Open API specification of a locale data model. To simplify this process these files are part of this repository but will be updated from time to time as the infrastructure specification evolves.

