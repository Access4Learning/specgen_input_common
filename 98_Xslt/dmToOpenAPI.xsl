<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet	version="2.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"  
    xmlns:specgen="http://sifassociation.org/SpecGen"
	xmlns:xfn="http://stuart.geek.nz/xslt-functions"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:xhtml="http://www.w3.org/1999/xhtml"
	xmlns:json="http://json.org/">

	<!-- Take a SIF_DataModel.input.xml file and produce a matching OpenAPI v3.0.0 spec -->
	<xsl:output method="text" omit-xml-declaration="yes" indent="no"/>
	
	<xsl:param name="sifVersion"/>
    <xsl:param name="sifLocale"/>
    <xsl:param name="sifObjectList" select="''"/> <!-- Default to empty list -->
    <!-- NN 20231102 Insert commas around parameter, for delimiter detection, to prevent spurious substring match -->
    <xsl:variable name="sifObjectList1">
        <xsl:value-of select="concat(',', $sifObjectList,',')"/>
    </xsl:variable>

    <xsl:param name="sifObjectGroupList" select="''"/> <!-- Default to empty list -->
    <xsl:param name="includeAllHeaders" select="'false'" as="xs:string"/> <!-- If false we only show minimum number of headers -->
    <xsl:param name="includeAdminDirectives" select="'false'" as="xs:string"/> <!-- If true admin directives endpoints will be included. -->
    <xsl:param name="omitVersionInExamplesFileName" select="'false'" as="xs:string"/> <!-- If true admin directives endpoints will be included. -->

    <!-- NN 20230116 Whether we are compliant with OpenAPI 3.0 JSON Schema (true), or full JSON Schema, i.e. OpenAPI 3.1 (false). -->
    <xsl:param name="openAPI30" select="'true'" as="xs:string"/> <!-- If true create Open API 3.0 spec which is more strict -->

    <!-- Get the Data Model URL from the Title Page -->
	<xsl:variable name="extDocUrlRoot">
		<xsl:value-of select="specgen:SIFSpecification/specgen:TitlePage/specgen:dl/specgen:dd[1]/specgen:a[@href]"/>
	</xsl:variable>

	<xsl:variable name="produceAllHeaders" as="xs:boolean"> <!-- Ensures that variable is of type boolean -->
		<xsl:value-of select="not(xfn:empty($includeAllHeaders)) and $includeAllHeaders = 'true'"/>
	</xsl:variable>
	
	<xsl:variable name="produceAdminDirectives" as="xs:boolean"> <!-- Ensures that variable is of type boolean -->
		<xsl:value-of select="not(xfn:empty($includeAdminDirectives)) and $includeAdminDirectives = 'true'"/>
	</xsl:variable>

	<xsl:variable name="exampleFileName">
		<xsl:if test="$omitVersionInExamplesFileName = 'true'">
			<xsl:value-of select="concat('examples_', $sifLocale, '.yaml')" />
		</xsl:if>
		<xsl:if test="not($omitVersionInExamplesFileName = 'true')">
			<xsl:value-of
				select="concat('examples_', $sifLocale, '_' , $sifVersion, '.yaml')" />
		</xsl:if>
	</xsl:variable>
	
	<xsl:variable name="generationTimestamp">
		<xsl:value-of select="current-dateTime()"/>
	</xsl:variable>

	<xsl:variable name="title">
		<xsl:if test="xfn:empty($sifObjectGroupList)">
		  	<xsl:value-of select="concat('SIF ', $sifLocale, ' API')"/>
		</xsl:if>
		<xsl:if test="not(xfn:empty($sifObjectGroupList))">
		  	<xsl:value-of select="$sifObjectGroupList"/>
		</xsl:if>
	</xsl:variable>

	<xsl:variable name="commonDefsFileName">
		<xsl:value-of select="'commonDefs.yaml'" />
		<!-- 
		<xsl:choose>
			<xsl:when test="$openAPI30 = 'true'">
				<xsl:if test="$produceAllHeaders">
					<xsl:value-of select="'commonDefs-OpenAPI3.0-all-headers.yaml'" />
				</xsl:if>
				<xsl:if test="not($produceAllHeaders)">
					<xsl:value-of select="'commonDefs-OpenAPI3.0-main-headers.yaml'" />
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:if test="$produceAllHeaders">
					<xsl:value-of select="'commonDefs-OpenAPI3.1-all-headers.yaml'" />
				</xsl:if>
				<xsl:if test="not($produceAllHeaders)">
					<xsl:value-of select="'commonDefs-OpenAPI3.1-main-headers.yaml'" />
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
		-->
	</xsl:variable>

	<xsl:variable name="openapi_version_lbl">
		<xsl:choose>
			<xsl:when test="$openAPI30 = 'true'">
				<xsl:value-of select='"_OpenAPI3.0_"' />
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select='"_OpenAPI3.1_"' />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>

	<xsl:variable name="openapi_version">
		<xsl:choose>
			<xsl:when test="$openAPI30 = 'true'">
				<xsl:value-of select='"3.0.3"' />
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select='"3.1.0"' />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	
	<xsl:template match="/specgen:SIFSpecification">
		<xsl:text># // Open API file for:&#x0a;</xsl:text>
		<xsl:value-of select="concat('# // Locale: ', $sifLocale, '&#x0a;')"/>
		<xsl:value-of select="concat('# // SIF Datamodel Version: ', $sifVersion, '&#x0a;')"/>
		<xsl:value-of select="concat('# // Limited to Objects: ', $sifObjectList, '&#x0a;')"/>
		<xsl:value-of select="concat('# // Limited to Groups: ', $sifObjectGroupList, '&#x0a;')"/>
		<xsl:value-of select="concat('# // Include all HTTP Headers: ', $produceAllHeaders, '&#x0a;')"/>
		<xsl:value-of select="concat('# // Include Admin Directive Endpoints: ', $produceAdminDirectives, '&#x0a;')"/>
		<xsl:value-of select="concat('# // OpenAPI version: ', $openapi_version, '&#x0a;')"/>
		<xsl:value-of select="concat('# // Referenced Example File Name: ', $exampleFileName, '&#x0a;')"/>
		<xsl:value-of select="concat('# // Schema File Version Label: ', $openapi_version_lbl, '&#x0a;')"/>
		<xsl:value-of select="concat('# // File Generated on: ', $generationTimestamp, '&#x0a;')"/>
		<xsl:text>&#x0a;</xsl:text>

		<xsl:value-of select="concat( 'openapi: ', $openapi_version, '&#x0a;',
                                      'info:&#x0a;',
                                      '  version: v', $sifVersion, '&#x0a;',
                                      '  title: ', $q , $title, $q, '&#x0a;',
                                      '  description: ', $q, normalize-space(specgen:TitlePage/specgen:h1), $q, '&#x0a;',
                                      '  license:&#x0a;',
                                      '    name: Copyright&#x0a;',
                                      '    url: ''https://home.a4l.org/legal/''&#x0a;',
                                      'servers:&#x0a;',
                                      '  - url: ''https://{tenant}/{root}''&#x0a;',
                                      '    variables:&#x0a;',
                                      '      tenant:&#x0a;',
                                      '        default: api.example.com&#x0a;',
                                      '        description: Your server host&#x0a;',
                                      '      root:&#x0a;',
                                      '        default: sif&#x0a;',
                                      '        description: optional root directory for SIF API&#x0a;',
                                      'security:&#x0a;',
                                      '  - basicAuth: []&#x0a;',
                                      '  - sifHMACSHA256: []&#x0a;',
                                      '  - bearerAuth: []&#x0a;',
                                      '&#x0a;','')"/>

        <!-- NN 20230116: add servers  -->
			  
		<!-- =================== -->
		<!-- Adds Groups section -->
		<!-- =================== -->
		
		<!-- Data objects groups -->
		<xsl:text># /////////////////////////////////////////////////////////////&#x0a;&#x0a;</xsl:text>
		<xsl:text>x-tagGroups:&#x0a;</xsl:text>
		<xsl:apply-templates select=".//specgen:DataObjects//specgen:Group" mode="TagGroups"/>

		<xsl:text># /////////////////////////////////////////////////////////////&#x0a;&#x0a;</xsl:text>
		<xsl:text>tags:&#x0a;</xsl:text>
		<xsl:apply-templates select=".//specgen:DataObjects//specgen:Group" mode="Tags"/>
		
		<!-- ==================================================== -->
		<!-- HTTP Operation Section: Add HTTP GET, PUT, POST etc. -->
		<!-- ==================================================== -->
		<xsl:text># /////////////////////////////////////////////////////////////&#x0a;&#x0a;</xsl:text>
		<xsl:apply-templates select=".//specgen:DataObjects" mode="paths"/>
		
		<!-- ============================================================================= -->
		<!-- Add schema defs, example defs, request defs and response defs for each object -->
		<!-- ============================================================================= -->
		<xsl:text>components:&#x0a;</xsl:text>
		<xsl:apply-templates select="." mode="securitySchemes"/>
                <!--<xsl:text>  schemas:&#x0a;</xsl:text>-->
		<xsl:apply-templates select=".//specgen:DataObjects" mode="requestPayloadDefinitions"/>
		<xsl:apply-templates select=".//specgen:DataObjects" mode="responsePayloadDefinitions"/>
		<xsl:apply-templates select=".//specgen:DataObjects" mode="schemaDefinitions"/>
    </xsl:template>

    <!-- NN 20230124 placeholder security scheme -->     
    <xsl:template match="*" mode="securitySchemes">
		<xsl:text>  securitySchemes:&#x0a;</xsl:text>
		<xsl:text>    basicAuth:&#x0a;</xsl:text>
		<xsl:text>      type: http&#x0a;</xsl:text>
		<xsl:text>      scheme: basic&#x0a;</xsl:text>
		<xsl:text>      description: "Click [here](https://a4ldocumentation.atlassian.net/wiki/spaces/ARCHITECTU/pages/220430337/Authentication+Options#Basic-Authentication) for more details about Basic Authentication."&#x0a;</xsl:text>
		<xsl:text>    sifHMACSHA256:&#x0a;</xsl:text>
		<xsl:text>      type: http&#x0a;</xsl:text>
		<xsl:text>      scheme: SIF_HMACSHA256&#x0a;</xsl:text>
		<xsl:text>      description: "Click [here](https://a4ldocumentation.atlassian.net/wiki/spaces/ARCHITECTU/pages/220430337/Authentication+Options#HMAC/SHA1-Based-Authentication) for more details about SIF HMAC256 Authentication."&#x0a;</xsl:text>
		<xsl:text>    bearerAuth:&#x0a;</xsl:text>
		<xsl:text>      type: http&#x0a;</xsl:text>
		<xsl:text>      scheme: bearer&#x0a;</xsl:text>
		<xsl:text>      description: "Click [here](https://a4ldocumentation.atlassian.net/wiki/spaces/ARCHITECTU/pages/220430337/Authentication+Options#OAuth-Authentication) for more details about OAuth Authentication."&#x0a;</xsl:text>
		<xsl:text>&#x0a;</xsl:text>
    </xsl:template>
	
	<!-- ========================================================= -->
	<!-- Tag Groups Section -->
	<!-- ========================================================= -->
	<!-- Use Groups that hold data objects to drive ToC -->
	<xsl:template match="specgen:Group" mode="TagGroups">
		<xsl:if test="xfn:containsOrEmpty($sifObjectGroupList, @name)">
			<xsl:if test="not(specgen:OpenAPI/specgen:ExcludeGroupName eq 'true')">
				<xsl:value-of select="concat('  - name: ', $q, @name, $q, '&#x0a;',
				                             '    tags:&#x0a;',
										     '      - ', $q, translate(@name, ' /-&amp;', ''), 'Overview', $q, '&#x0a;')"/>
		
			   <xsl:apply-templates select="specgen:DataObject" mode="TagGroups"/>
		   </xsl:if>
	   </xsl:if>
	</xsl:template>
	
        <xsl:template match="specgen:DataObject" mode="TagGroups">
                <!-- NN 20231102 Insert commas around @name, for delimiter detection, to prevent spurious substring match -->
                <xsl:variable name="commadelim_name">
                        <xsl:value-of select="concat(',', @name,',')"/>
                </xsl:variable>
                <xsl:if test="xfn:containsOrEmpty($sifObjectList1, $commadelim_name)">
			<xsl:variable name="excludeOps" select="specgen:OpenAPI/specgen:ExcludeOperations"/>
		
			<xsl:if test="not(contains($excludeOps,'ALL'))">
				<xsl:value-of select="concat('      - ', $q, @name, $q, '&#x0a;')"/>
			</xsl:if>
		</xsl:if>
	</xsl:template>

	<xsl:template match="specgen:Group" mode="Tags">
		<xsl:if test="xfn:containsOrEmpty($sifObjectGroupList, @name)">
			<xsl:if test="not(specgen:OpenAPI/specgen:ExcludeGroupName eq 'true')">
			
				<xsl:value-of select="concat('  - name: ', $q, translate(@name, ' /-&amp;', ''), 'Overview', $q, '&#x0a;',
				                             '    x-displayName: ', $q, @name, ' Overview', $q, '&#x0a;',
											 '    description: &gt;-&#x0a;      ')"/>
				<xsl:apply-templates select="specgen:Intro"/><xsl:text>&#x0a;</xsl:text>
				<xsl:value-of select="concat('    externalDocs: &#x0a;',
				                             '      description: &quot;', @name, ' Domain in SIF ',$sifLocale, ' v', $sifVersion, ' Data Model&quot;&#x0a;',
				                			 '      url: &quot;', $extDocUrlRoot, '&quot;&#x0a;')"/>             
				<xsl:apply-templates select="specgen:DataObject" mode="Tags"/>
			</xsl:if>
		</xsl:if>
	</xsl:template>

        <xsl:template match="specgen:DataObject" mode="Tags">
                <!-- NN 20231102 Insert commas around @name, for delimiter detection, to prevent spurious substring match -->
                <xsl:variable name="commadelim_name">
                        <xsl:value-of select="concat(',', @name,',')"/>
                </xsl:variable>
                <xsl:if test="xfn:containsOrEmpty($sifObjectList1, $commadelim_name)">
			<xsl:variable name="excludeOps" select="specgen:OpenAPI/specgen:ExcludeOperations"/>
		
			<xsl:if test="not(contains($excludeOps,'ALL'))">
			    <xsl:value-of select="concat('  - name: ', $q, @name, $q, '&#x0a;',
											 '    description: &gt;-&#x0a;      ')"/>
				<xsl:apply-templates select="specgen:Item[1]/specgen:Description"/><xsl:text>&#x0a;</xsl:text>
			</xsl:if>
		</xsl:if>
	</xsl:template>

	<!-- ==================================== -->
	<!-- Section: Request Payload Definitions -->
	<!-- ==================================== -->
	<xsl:template match="specgen:DataObjects" mode="requestPayloadDefinitions">
		<xsl:text>  requestBodies:&#x0a;</xsl:text>
		<xsl:text>&#x0a;</xsl:text>
		<xsl:text>    # /////////////////////////////////&#x0a;</xsl:text>
		<xsl:text>    # // Request Payload Definitions //&#x0a;</xsl:text>
		<xsl:text>    # /////////////////////////////////&#x0a;</xsl:text>
		<!-- NN 20230124 remove nesting of children of components/schemas -->
		<!-- <xsl:text> requestPayloads:&#x0a;</xsl:text> -->
		<xsl:apply-templates select=".//specgen:DataObject"	mode="requestPayloadDefinitions" />
	</xsl:template>

        <xsl:template match="specgen:DataObject" mode="requestPayloadDefinitions">
                <!-- NN 20231102 Insert commas around @name, for delimiter detection, to prevent spurious substring match -->
                <xsl:variable name="commadelim_name">
                        <xsl:value-of select="concat(',', @name,',')"/>
                </xsl:variable>
                <xsl:if test="xfn:containsOrEmpty($sifObjectList1, $commadelim_name)">
			<xsl:variable name="excludeOps" select="specgen:OpenAPI/specgen:ExcludeOperations"/>
	
			<xsl:if test="not(contains($excludeOps,'ALL'))">
				<xsl:text>      #//&#x0a;</xsl:text>
				<xsl:value-of select="concat('      #// ', @name, '&#x0a;')"/>
				<xsl:text>      #//&#x0a;</xsl:text>
				<xsl:apply-templates select="." mode="payloadDefinition">
					<xsl:with-param name="schemaID">create</xsl:with-param>
                                        <!-- NN 20230124 remove nesting of children of components/schemas -->
                                        <!--<xsl:with-param name="schemaID">create</xsl:with-param>-->
					<xsl:with-param name="objectName"><xsl:value-of select="@name"/></xsl:with-param>
				</xsl:apply-templates>
				<xsl:text>&#x0a;</xsl:text>
				<xsl:apply-templates select="." mode="payloadDefinition">
					<xsl:with-param name="schemaID">update</xsl:with-param>
					<xsl:with-param name="objectName"><xsl:value-of select="@name"/></xsl:with-param>
				</xsl:apply-templates>
				<xsl:text>&#x0a;</xsl:text>
				<xsl:apply-templates select="." mode="payloadDefinition">
					<xsl:with-param name="schemaID">create</xsl:with-param>
					<xsl:with-param name="objectName"><xsl:value-of select="concat(@name, 's')"/></xsl:with-param>
				</xsl:apply-templates>
				<xsl:text>&#x0a;</xsl:text>
				<xsl:apply-templates select="." mode="payloadDefinition">
					<xsl:with-param name="schemaID">update</xsl:with-param>
					<xsl:with-param name="objectName"><xsl:value-of select="concat(@name, 's')"/></xsl:with-param>
					<xsl:with-param name="addBatchDeleletRequest">true</xsl:with-param>
				</xsl:apply-templates>
				<xsl:text>&#x0a;</xsl:text>
			</xsl:if>
		</xsl:if>
	</xsl:template>

	<!-- ===================================== -->
	<!-- Section: Response Payload Definitions -->
	<!-- ===================================== -->
	<xsl:template match="specgen:DataObjects" mode="responsePayloadDefinitions">
                <xsl:text>  responses:&#x0a;</xsl:text>
		<xsl:text>&#x0a;</xsl:text>
		<xsl:text>    # //////////////////////////////////&#x0a;</xsl:text>
		<xsl:text>    # // Response Payload Definitions //&#x0a;</xsl:text>
		<xsl:text>    # //////////////////////////////////&#x0a;</xsl:text>
                <!-- NN 20230124 remove nesting of children of components/schemas -->
                <!--<xsl:text>    responsePayloads:&#x0a;</xsl:text>-->
		<xsl:apply-templates select=".//specgen:DataObject" mode="responsePayloadDefinitions"/>
	</xsl:template>

        <xsl:template match="specgen:DataObject" mode="responsePayloadDefinitions">
                <!-- NN 20231102 Insert commas around @name, for delimiter detection, to prevent spurious substring match -->
                <xsl:variable name="commadelim_name">
                        <xsl:value-of select="concat(',', @name,',')"/>
                </xsl:variable>
                <xsl:if test="xfn:containsOrEmpty($sifObjectList1, $commadelim_name)">
			<xsl:variable name="excludeOps" select="specgen:OpenAPI/specgen:ExcludeOperations"/>
	
			<xsl:if test="not(contains($excludeOps,'ALL'))">
				<xsl:text>      #//&#x0a;</xsl:text>
				<xsl:value-of select="concat('      #// ', @name, '&#x0a;')"/>
				<xsl:text>      #//&#x0a;</xsl:text>
				
				<!-- 
					Single Object Create Info
				 -->
				<xsl:apply-templates select="." mode="payloadDefinition">
                                        <!-- NN 20230124 remove nesting of children of components/schemas -->
                                        <!--<xsl:with-param name="schemaID">create</xsl:with-param> -->
					<xsl:with-param name="schemaID">create</xsl:with-param>
					<xsl:with-param name="objectName"><xsl:value-of select="@name"/></xsl:with-param>
				</xsl:apply-templates>
	
				<!-- Response Headers -->
				<xsl:apply-templates select="." mode="addResponseHeaders">
					<xsl:with-param name="pfx"><xsl:text>        </xsl:text></xsl:with-param>
					<xsl:with-param name="excludeHeaders">
						<!--xsl:value-of select="concat(specgen:OpenAPI/specgen:GetSingle/specgen:ExcludeResponseHTTPHeaders, ',accept, accept-encoding, accept-profile, changesSinceMarkerHead,changesSinceMarkerGet, navigationCount, navigationId, navigationLastPage, navigationPage, navigationPageSize')"/-->
						<xsl:value-of select="concat(specgen:OpenAPI/specgen:GetSingle/specgen:ExcludeResponseHTTPHeaders, 'serviceSubType',
						                             xfn:conditinalConcat(not($produceAllHeaders),',accept, accept-encoding, accept-profile, changesSinceMarkerHead,changesSinceMarkerGet, dataPrivacyMarkerBatchPutResponse, navigationCount, navigationId, navigationLastPage, navigationPage, navigationPageSize',',requestId'))"/>
					</xsl:with-param>
				</xsl:apply-templates>
				<xsl:text>&#x0a;</xsl:text>
	
				<!-- 
					Single Object Update Info
				 -->
				<xsl:apply-templates select="." mode="payloadDefinition">
					<xsl:with-param name="schemaID">update</xsl:with-param>
					<xsl:with-param name="objectName"><xsl:value-of select="@name"/></xsl:with-param>
				</xsl:apply-templates>
	
				<!-- Response Headers -->
				<xsl:apply-templates select="." mode="addResponseHeaders">
					<xsl:with-param name="pfx"><xsl:text>        </xsl:text></xsl:with-param>
					<xsl:with-param name="excludeHeaders">
						<!--xsl:value-of select="concat(specgen:OpenAPI/specgen:PutSingle/specgen:ExcludeResponseHTTPHeaders, ',accept, accept-encoding, accept-profile, changesSinceMarkerHead,changesSinceMarkerGet, navigationCount, navigationId, navigationLastPage, navigationPage, navigationPageSize')"/-->
						<xsl:value-of select="concat(specgen:OpenAPI/specgen:PutSingle/specgen:ExcludeResponseHTTPHeaders, 'serviceSubType',
						                     xfn:conditinalConcat(not($produceAllHeaders),',accept, accept-encoding, accept-profile, changesSinceMarkerHead,changesSinceMarkerGet, dataPrivacyMarkerBatchPutResponse, navigationCount, navigationId, navigationLastPage, navigationPage, navigationPageSize',',requestId'))"/>
					</xsl:with-param>
				</xsl:apply-templates>
				<xsl:text>&#x0a;</xsl:text>
	
				<!-- 
					Collection Object: Response for standard GET
				 -->
				<xsl:apply-templates select="." mode="payloadDefinition">
					<xsl:with-param name="schemaID">create</xsl:with-param>
					<xsl:with-param name="objectName"><xsl:value-of select="concat(@name, 's')"/></xsl:with-param>
				</xsl:apply-templates>
				
				<!-- Response Headers -->
				<xsl:apply-templates select="." mode="addResponseHeaders">
					<xsl:with-param name="pfx"><xsl:text>        </xsl:text></xsl:with-param>
					<xsl:with-param name="excludeHeaders">
						<xsl:value-of select="concat(specgen:OpenAPI/specgen:GetBatch/specgen:ExcludeResponseHTTPHeaders, ',changesSinceMarkerHead, dataPrivacyMarkerBatchPutResponse, serviceSubType')"/>
					</xsl:with-param>
				</xsl:apply-templates>
				<xsl:text>&#x0a;</xsl:text>
	
				<!--
					Collection Object: Response for POST when methodoveride="GET" => QBE!
				-->
				<xsl:apply-templates select="." mode="payloadDefinition">
					<xsl:with-param name="schemaID">create</xsl:with-param>
					<xsl:with-param name="objectName"><xsl:value-of select="concat(@name, 's')"/></xsl:with-param>
					<xsl:with-param name="isQBE">true</xsl:with-param>
				</xsl:apply-templates>
				
				<!-- Response Headers -->
				<xsl:apply-templates select="." mode="addResponseHeaders">
					<xsl:with-param name="pfx"><xsl:text>        </xsl:text></xsl:with-param>
					<xsl:with-param name="excludeHeaders">
						<xsl:value-of select="concat(specgen:OpenAPI/specgen:GetBatch/specgen:ExcludeResponseHTTPHeaders, ',changesSinceMarkerHead,changesSinceMarkerGet,dataPrivacyMarkerBatchPutResponse,serviceSubType')"/>
					</xsl:with-param>
				</xsl:apply-templates>
				<xsl:text>&#x0a;</xsl:text>
	
				<!--
					We do not add a collection update response as it is always a 'batch' update response and this is in the
					commonDefs.yaml.
				-->
			</xsl:if>
		</xsl:if>
	</xsl:template>

	<!-- ===================================================== -->
	<!-- Template for producing info about payload Definitions -->
	<!-- ===================================================== -->
	<xsl:template match="specgen:DataObject" mode="payloadDefinition">
		<xsl:param name="schemaID"/>
		<xsl:param name="objectName"/>
		<xsl:param name="isQBE"/>
		<xsl:param name="addBatchDeleletRequest"/>

		<xsl:if test="$isQBE = 'true'">
			<xsl:value-of select="concat('      ', $schemaID, $objectName, 'QBE:&#x0a;')"/>
			<xsl:value-of select="concat('        description: Payload for Multiple POST request for ', $objectName, '&#x0a;')"/>
		</xsl:if>
		<xsl:if test="not($isQBE = 'true')">
			<xsl:value-of select="concat('      ', $schemaID, $objectName, ':&#x0a;')"/>
			<xsl:value-of select="concat('        description: Payload for ', $objectName, '&#x0a;')"/>
		</xsl:if>
		<xsl:text>        content:&#x0a;</xsl:text>
		<xsl:text>          application/json:&#x0a;</xsl:text>
		<xsl:text>            schema:&#x0a;</xsl:text>
		
		<xsl:if test="$isQBE = 'true'">
			<xsl:text>              oneOf:&#x0a;</xsl:text>
			<xsl:value-of select="concat('                - $ref: ''#/components/schemas/', $schemaID, 'Schema', $objectName, '''&#x0a;')" />
            <!-- NN 20230123 no attributes next to JSON References -->
            <xsl:if test="not($openAPI30 = 'true')">
                <xsl:value-of select="concat('                  title: ', $objectName, '&#x0a;')"/>
            </xsl:if>
		    <!--xsl:value-of select="concat('                - $ref: ''commonDefs.yaml#/components/schemas/multipleResponses/createMultiSchema', '''&#x0a;')"/-->
			<xsl:value-of select="concat('                - $ref: ''',$commonDefsFileName,'#/components/schemas/multipleResponses/createMultiSchema', '''&#x0a;')"/>
            <xsl:if test="not($openAPI30 = 'true')">
                <xsl:value-of select="concat('                  title: createRequest', '&#x0a;')"/>
            </xsl:if>
		</xsl:if>
		<xsl:if test="not($isQBE = 'true')">
		    <xsl:if test="not($addBatchDeleletRequest = 'true')">
			    <xsl:value-of select="concat('              $ref: ''#/components/schemas/', $schemaID, 'Schema', $objectName, '''&#x0a;')"/>
		    </xsl:if>
		    <xsl:if test="$addBatchDeleletRequest = 'true'">
			    <xsl:text>              oneOf:&#x0a;</xsl:text>
			    <xsl:value-of select="concat('                - $ref: ''#/components/schemas/', $schemaID, 'Schema', $objectName, '''&#x0a;')"/>
                <xsl:if test="not($openAPI30 = 'true')">
			        <xsl:value-of select="concat('                  title: ', $objectName, '&#x0a;')"/>
                </xsl:if>
			    <xsl:value-of select="concat('                - $ref: ''',$commonDefsFileName,'#/components/schemas/multipleRequests/deleteMultiSchema', '''&#x0a;')"/>
                <xsl:if test="not($openAPI30 = 'true')">
			        <xsl:value-of select="concat('                  title: deleteRequest', '&#x0a;')"/>
                </xsl:if>
		    </xsl:if>
		</xsl:if>
		<xsl:text>            examples:&#x0a;</xsl:text>
		<xsl:if test="$isQBE = 'true'">
			<xsl:value-of select="concat('              qbe', 'PESC:', '&#x0a;')"/>
            <xsl:value-of select="concat('                $ref: ''',$commonDefsFileName,'#/components/schemas/multipleResponses/createMultiExamples/pesc', '''&#x0a;')"/>
            <xsl:if test="not($openAPI30 = 'true')">
			    <xsl:value-of select="concat('              qbe', 'Goessner:', '&#x0a;')"/>
                <xsl:value-of select="concat('                $ref: ''',$commonDefsFileName,'#/components/schemas/multipleResponses/createMultiExamples/goessner', '''&#x0a;')"/>
            </xsl:if>
		</xsl:if>		
		<xsl:value-of select="concat('              ', $schemaID, 'PESC:', '&#x0a;')"/>
		<xsl:value-of select="concat('                $ref: ''', $exampleFileName, '#/objectExamples/', $objectName, '/pesc''&#x0a;')"/>
        <xsl:if test="not($openAPI30 = 'true')">
		    <xsl:value-of select="concat('              ', $schemaID, 'Goessner:', '&#x0a;')"/>
            <xsl:value-of select="concat('                $ref: ''', $exampleFileName, '#/objectExamples/', $objectName, '/goessner''&#x0a;')"/>
        </xsl:if>
	  	<xsl:if test="$addBatchDeleletRequest = 'true'">
			<xsl:value-of select="concat('              ', 'deletePESC:', '&#x0a;')"/>
			<xsl:value-of select="concat('                $ref: ''',$commonDefsFileName,'#/components/schemas/multipleRequests/deleteMultiExamples/pesc', '''&#x0a;')"/>
            <xsl:if test="not($openAPI30 = 'true')">
		        <xsl:value-of select="concat('              ', 'deleteGoessner:', '&#x0a;')"/>
                <xsl:value-of select="concat('                $ref: ''',$commonDefsFileName,'#/components/schemas/multipleRequests/deleteMultiExamples/goessner', '''&#x0a;')"/>
            </xsl:if>
		</xsl:if>
        <xsl:if test="not($openAPI30 = 'true')">
		    <xsl:text>          application/xml:&#x0a;</xsl:text>
		    <xsl:text>            schema:&#x0a;</xsl:text>
		    <xsl:if test="$isQBE = 'true'">
			    <xsl:text>              oneOf:&#x0a;</xsl:text>
			    <xsl:value-of select="concat('                - $ref: ''#/components/schemas/', $schemaID, 'Schema', $objectName, '''&#x0a;')"/>
                <xsl:if test="not($openAPI30 = 'true')">
			        <xsl:value-of select="concat('                  title: ', $objectName, '&#x0a;')"/>
                </xsl:if>
			    <xsl:value-of select="concat('                - $ref: ''',$commonDefsFileName,'#/components/schemas/multipleResponses/createMultiSchema', '''&#x0a;')"/>
                <xsl:if test="not($openAPI30 = 'true')">
			        <xsl:value-of select="concat('                  title: createRequest', '&#x0a;')"/>
                </xsl:if>
		    </xsl:if>
		    <xsl:if test="not($isQBE = 'true')">
		        <xsl:if test="not($addBatchDeleletRequest = 'true')">
			        <xsl:value-of select="concat('              $ref: ''#/components/schemas/', $schemaID, 'Schema', $objectName, '''&#x0a;')"/>
		        </xsl:if>
		        <xsl:if test="$addBatchDeleletRequest = 'true'">
			        <xsl:text>              oneOf:&#x0a;</xsl:text>
			        <xsl:value-of select="concat('                - $ref: ''#/components/schemas/', $schemaID, 'Schema', $objectName, '''&#x0a;')"/>
                    <xsl:if test="not($openAPI30 = 'true')">
			            <xsl:value-of select="concat('                  title: ', $objectName, '&#x0a;')"/>
                    </xsl:if>
			        <xsl:value-of select="concat('                - $ref: ''',$commonDefsFileName,'#/components/schemas/multipleRequests/deleteMultiSchema', '''&#x0a;')"/>
                    <xsl:if test="not($openAPI30 = 'true')">
			            <xsl:value-of select="concat('                  title: deleteRequest', '&#x0a;')"/>
                    </xsl:if>
		        </xsl:if>
            </xsl:if>
		    <xsl:text>            examples:&#x0a;</xsl:text>
		    <xsl:if test="$isQBE = 'true'">
			    <xsl:value-of select="concat('              qbe', 'XML:', '&#x0a;')"/>
			    <xsl:value-of select="concat('                $ref: ''',$commonDefsFileName,'#/components/schemas/multipleResponses/createMultiExamples/xml', '''&#x0a;')"/>
		    </xsl:if>		
		    <xsl:value-of select="concat('              ', $schemaID, 'XML:', '&#x0a;')"/>
		    <xsl:value-of select="concat('                $ref: ''', $exampleFileName, '#/objectExamples/', $objectName, '/xml''&#x0a;')"/>
	  	    <xsl:if test="$addBatchDeleletRequest = 'true'">
			    <xsl:value-of select="concat('              ', 'deleteXML:', '&#x0a;')"/>
			    <xsl:value-of select="concat('                $ref: ''',$commonDefsFileName,'#/components/schemas/multipleRequests/deleteMultiExamples/xml', '''&#x0a;')"/>
            </xsl:if>
        </xsl:if>
	</xsl:template>

	<!-- =========================== -->
	<!-- Section: Schema Definitions -->
	<!-- =========================== -->
	<xsl:template match="specgen:DataObjects" mode="schemaDefinitions">
                <xsl:text>  schemas:&#x0a;</xsl:text>
		<xsl:text>&#x0a;</xsl:text>
		<xsl:text>    # ////////////////////////&#x0a;</xsl:text>
		<xsl:text>    # // Schema Definitions //&#x0a;</xsl:text>
		<xsl:text>    # ////////////////////////&#x0a;</xsl:text>
                <!-- NN 20230123 no attributes next to JSON References -->
                <!--<xsl:text>    schemaDefinitions:&#x0a;</xsl:text>-->
		<xsl:apply-templates select=".//specgen:DataObject" mode="schemaDefinitions"/>
	</xsl:template>

        <xsl:template match="specgen:DataObject" mode="schemaDefinitions">
                <!-- NN 20231102 Insert commas around @name, for delimiter detection, to prevent spurious substring match -->
                <xsl:variable name="commadelim_name">
                        <xsl:value-of select="concat(',', @name,',')"/>
                </xsl:variable>
                <xsl:if test="xfn:containsOrEmpty($sifObjectList1, $commadelim_name)">
			<xsl:variable name="excludeOps" select="specgen:OpenAPI/specgen:ExcludeOperations"/>
	
			<xsl:if test="not(contains($excludeOps,'ALL'))">
				<xsl:text>      #//&#x0a;</xsl:text>
				<xsl:value-of select="concat('      #// ', @name, '&#x0a;')"/>
				<xsl:text>      #//&#x0a;</xsl:text>
				<xsl:apply-templates select="." mode="singleSchemaDef"/>
				<xsl:apply-templates select="." mode="collectionSchemaDef"/>
			</xsl:if>
		</xsl:if>
	</xsl:template>

	<!-- ================================================================ -->
	<!-- Template for producing info about Schema Defs for Single Objects -->
	<!-- ================================================================ -->
	<xsl:template match="specgen:DataObject" mode="singleSchemaDef">
		<xsl:value-of select="concat('      updateSchema', @name, ':&#x0a;')"/>
		<xsl:text>        properties:&#x0a;</xsl:text>
		<xsl:value-of select="concat('          ', @name, ':&#x0a;')"/>
		<xsl:text>            type: object&#x0a;</xsl:text>
		<xsl:value-of select="concat('            description: >-', '&#x0a;', '              Payload definition for ', @name, '&#x0a;')"/>
                <!-- NN 20221216 exceptionally, LearningResourcePackage is an OBJECT that is an alias of a type, and the type can only be defined once -->
		<xsl:value-of select="concat('            $ref: ''jsonSchema', $openapi_version_lbl, 'Update_', $sifLocale, '.yaml#/definitions/', xfn:refresolve(@name), '''&#x0a;')"/>
		<xsl:text>&#x0a;</xsl:text>
		<xsl:value-of select="concat('      createSchema', @name, ':&#x0a;')"/>
		<xsl:text>        properties:&#x0a;</xsl:text>
		<xsl:value-of select="concat('          ', @name, ':&#x0a;')"/>
		<xsl:text>            type: object&#x0a;</xsl:text>
                <xsl:value-of select="concat('            description: >-', '&#x0a;', '              Payload definition for ', @name, '&#x0a;')"/>
                <!-- NN 20221216 exceptionally, LearningResourcePackage is an OBJECT that is an alias of a type, and the type can only be defined once -->
		<xsl:value-of select="concat('            $ref: ''jsonSchema', $openapi_version_lbl, 'Create_', $sifLocale, '.yaml#/definitions/', xfn:refresolve(@name), '''&#x0a;')"/>
		<xsl:text>&#x0a;</xsl:text>
	</xsl:template>

	<!-- ============================================================= -->
	<!-- Template for producing info about Schema Def for List Objects -->
	<!-- ============================================================= -->
        <!-- NN 20221216 exceptionally, LearningResourcePackage is an OBJECT that is an alias of a type, and the type can only be defined once: introduced xfn:refresolve -->
        <!-- NN 20230116 does not apply to object collection types, which are still distinct -->
        <!-- NN 20221219 force schema def to be PESC-conformant for lists, previous instance was Goessner-conformant -->
    <xsl:template match="specgen:DataObject" mode="collectionSchemaDef">
          <!-- old
		<xsl:value-of select="concat('      updateSchema', @name, 's:&#x0a;')"/>
		<xsl:text>        properties:&#x0a;</xsl:text>
		<xsl:value-of select="concat('          ', @name, 's:&#x0a;')"/>
		<xsl:text>            type: object&#x0a;</xsl:text>
		<xsl:text>            description: >-&#x0a;</xsl:text>
		<xsl:value-of select="concat('              A Collection of ', @name, ' objects&#x0a;')"/>
		<xsl:text>            properties:&#x0a;</xsl:text>
		<xsl:value-of select="concat('              ', @name, ':&#x0a;')"/>
		<xsl:text>                type: array&#x0a;</xsl:text>
		<xsl:text>                items:&#x0a;</xsl:text>
		<xsl:value-of select="concat('                  $ref: ''jsonSchema', 'Update_', $sifLocale, '.yaml#/definitions/', xfn:refresolve(@name), '''&#x0a;')"/>
		<xsl:text>&#x0a;</xsl:text>
		
		<xsl:value-of select="concat('      createSchema', @name, 's:&#x0a;')"/>
		<xsl:text>        properties:&#x0a;</xsl:text>
		<xsl:value-of select="concat('          ', @name, 's:&#x0a;')"/>
		<xsl:text>            type: object&#x0a;</xsl:text>
		<xsl:text>            description: >-&#x0a;</xsl:text>
		<xsl:value-of select="concat('              A Collection of ', @name, ' objects&#x0a;')"/>
		<xsl:text>            properties:&#x0a;</xsl:text>
		<xsl:value-of select="concat('              ', @name, ':&#x0a;')"/>
		<xsl:text>                type: array&#x0a;</xsl:text>
		<xsl:text>                items:&#x0a;</xsl:text>
                <xsl:value-of select="concat('                  $ref: ''jsonSchema', 'Create_', $sifLocale, '.yaml#/definitions/', xfn:refresolve(@name), '''&#x0a;')"/>
                <xsl:text>&#x0a;</xsl:text>
            -->
        <xsl:value-of select="concat('      updateSchema', @name, 's:&#x0a;')"/>
        <xsl:text>        properties:&#x0a;</xsl:text>
        <xsl:value-of select="concat('          ', @name, 's:&#x0a;')"/>
        <xsl:text>            type: object&#x0a;</xsl:text>
        <xsl:text>            description: >-&#x0a;</xsl:text>
        <xsl:value-of select="concat('              A Collection of ', @name, ' objects&#x0a;')"/>
                <!-- NN 20221221 point direct to collections object -->
                <!--
                <xsl:text>            properties:&#x0a;</xsl:text>
                <xsl:value-of select="concat('              ', @name, ':&#x0a;')"/>
                <xsl:text>                type: array&#x0a;</xsl:text>
                <xsl:text>                items:&#x0a;</xsl:text>
                  <xsl:value-of select="concat('                    $ref: ''jsonSchema', 'Update_', $sifLocale, '.yaml#/definitions/', xfn:refresolve(@name),  '''&#x0a;')"/>
                 -->
        <xsl:value-of select="concat('            $ref: ''jsonSchema', $openapi_version_lbl, 'Update_', $sifLocale, '.yaml#/definitions/', @name,  'Collection''&#x0a;')"/>
        <xsl:text>&#x0a;</xsl:text>
        
        <xsl:value-of select="concat('      createSchema', @name, 's:&#x0a;')"/>
        <xsl:text>        properties:&#x0a;</xsl:text>
        <xsl:value-of select="concat('          ', @name, 's:&#x0a;')"/>
        <xsl:text>            type: object&#x0a;</xsl:text>
        <xsl:text>            description: >-&#x0a;</xsl:text>
        <xsl:value-of select="concat('              A Collection of ', @name, ' objects&#x0a;')"/>
                <!-- NN 20221221 point direct to collections object -->
                <!--
                <xsl:text>            properties:&#x0a;</xsl:text>
                <xsl:value-of select="concat('              ', @name, ':&#x0a;')"/>
                <xsl:text>                type: array&#x0a;</xsl:text>
                  <xsl:text>                items:&#x0a;</xsl:text>
                  <xsl:value-of select="concat('                    $ref: ''jsonSchema', 'Create_', $sifLocale, '.yaml#/definitions/', xfn:refresolve(@name),  '''&#x0a;')"/>
                 -->
        <xsl:value-of select="concat('            $ref: ''jsonSchema', $openapi_version_lbl, 'Create_', $sifLocale, '.yaml#/definitions/', @name,  'Collection''&#x0a;')"/>
        <xsl:text>&#x0a;</xsl:text>
	</xsl:template>

	<!-- ============================= -->
	<!-- Template for Response Headers -->
	<!-- ============================= -->
	<xsl:template match="*" mode="addResponseHeaders">
	    <xsl:param name="pfx"/>
		<xsl:param name="excludeHeaders"/>

		<xsl:value-of select="concat($pfx, 'headers:&#x0a;')"/>
		
		<xsl:if test="$produceAllHeaders">
			<xsl:if test="not(contains($excludeHeaders, 'accept'))">
				<xsl:value-of select="concat($pfx, '  ''accept'':&#x0a;')"/>
				<xsl:value-of select="concat($pfx, '    $ref: ''',$commonDefsFileName,'#/components/schemas/httpHeaders/response/accept''&#x0a;')"/>
			</xsl:if>
	
			<xsl:if test="not(contains($excludeHeaders, 'content-type'))">
				<xsl:value-of select="concat($pfx, '  ''content-type'':&#x0a;')"/>
				<xsl:value-of select="concat($pfx, '    $ref: ''',$commonDefsFileName,'#/components/schemas/httpHeaders/response/content-type''&#x0a;')"/>
			</xsl:if>
			
			<xsl:if test="not(contains($excludeHeaders, 'content-encoding'))">
				<xsl:value-of select="concat($pfx, '  ''content-encoding'':&#x0a;')"/>
				<xsl:value-of select="concat($pfx, '    $ref: ''',$commonDefsFileName,'#/components/schemas/httpHeaders/response/content-encoding''&#x0a;')"/>
			</xsl:if>
	
			<xsl:if test="not(contains($excludeHeaders, 'content-profile'))">
				<xsl:value-of select="concat($pfx, '  ''content-profile'':&#x0a;')"/>
				<xsl:value-of select="concat($pfx, '    $ref: ''',$commonDefsFileName,'#/components/schemas/httpHeaders/response/content-profile''&#x0a;')"/>
			</xsl:if>
		</xsl:if>

		<xsl:if test="not(contains($excludeHeaders, 'changesSinceMarkerGet'))">
			<xsl:value-of select="concat($pfx, '  ''changesSinceMarker'':&#x0a;')"/>
			<xsl:value-of select="concat($pfx, '    $ref: ''',$commonDefsFileName,'#/components/schemas/httpHeaders/response/changesSinceMarkerGet''&#x0a;')"/>
		</xsl:if>

		<xsl:if test="not(contains($excludeHeaders, 'changesSinceMarkerHead'))">
			<xsl:value-of select="concat($pfx, '  ''changesSinceMarker'':&#x0a;')"/>
			<xsl:value-of select="concat($pfx, '    $ref: ''',$commonDefsFileName,'#/components/schemas/httpHeaders/response/changesSinceMarkerHead''&#x0a;')"/>
		</xsl:if>
		
		<xsl:if test="$produceAllHeaders">
			<xsl:if test="not(contains($excludeHeaders, 'dataPrivacyMarkerStd'))">
				<xsl:value-of select="concat($pfx, '  ''dataPrivacyMarker'':&#x0a;')"/>
				<xsl:value-of select="concat($pfx, '    $ref: ''',$commonDefsFileName,'#/components/schemas/httpHeaders/response/dataPrivacyMarkerStd''&#x0a;')"/>
			</xsl:if>		
		
			<xsl:if test="not(contains($excludeHeaders, 'dataPrivacyMarkerBatchPutResponse'))">
				<xsl:value-of select="concat($pfx, '  ''dataPrivacyMarker'':&#x0a;')"/>
				<xsl:value-of select="concat($pfx, '    $ref: ''',$commonDefsFileName,'#/components/schemas/httpHeaders/response/dataPrivacyMarkerBatchPutResponse''&#x0a;')"/>
			</xsl:if>		

			<xsl:if test="not(contains($excludeHeaders, 'environmentURI'))">
				<xsl:value-of select="concat($pfx, '  ''environmentURI'':&#x0a;')"/>
				<xsl:value-of select="concat($pfx, '    $ref: ''',$commonDefsFileName,'#/components/schemas/httpHeaders/response/environmentURI''&#x0a;')"/>
			</xsl:if>

<!-- 	
			<xsl:if test="not(contains($excludeHeaders, 'ETag'))">
				<xsl:value-of select="concat($pfx, '  ''ETag'':&#x0a;')"/>
				<xsl:value-of select="concat($pfx, '    $ref: ''',$commonDefsFileName,'#/components/schemas/httpHeaders/response/ETag''&#x0a;')"/>
			</xsl:if>
-->	
			<xsl:if test="not(contains($excludeHeaders, 'fingerprint'))">
				<xsl:value-of select="concat($pfx, '  ''fingerprint'':&#x0a;')"/>
				<xsl:value-of select="concat($pfx, '    $ref: ''',$commonDefsFileName,'#/components/schemas/httpHeaders/response/fingerprint''&#x0a;')"/>
			</xsl:if>
	
			<xsl:if test="not(contains($excludeHeaders, 'messageId'))">
				<xsl:value-of select="concat($pfx, '  ''messageId'':&#x0a;')"/>
				<xsl:value-of select="concat($pfx, '    $ref: ''',$commonDefsFileName,'#/components/schemas/httpHeaders/response/messageId''&#x0a;')"/>
			</xsl:if>
		</xsl:if>
				
		<xsl:if test="not(contains($excludeHeaders, 'messageType'))">
			<xsl:value-of select="concat($pfx, '  ''messageType'':&#x0a;')"/>
			<xsl:value-of select="concat($pfx, '    $ref: ''',$commonDefsFileName,'#/components/schemas/httpHeaders/response/messageType''&#x0a;')"/>
		</xsl:if>

		<xsl:if test="not(contains($excludeHeaders, 'navigationCount'))">
			<xsl:value-of select="concat($pfx, '  ''navigationCount'':&#x0a;')"/>
			<xsl:value-of select="concat($pfx, '    $ref: ''',$commonDefsFileName,'#/components/schemas/httpHeaders/response/navigationCount''&#x0a;')"/>
		</xsl:if>

		<xsl:if test="not(contains($excludeHeaders, 'navigationId'))">
			<xsl:value-of select="concat($pfx, '  ''navigationId'':&#x0a;')"/>
			<xsl:value-of select="concat($pfx, '    $ref: ''',$commonDefsFileName,'#/components/schemas/httpHeaders/response/navigationId''&#x0a;')"/>
		</xsl:if>

		<xsl:if test="not(contains($excludeHeaders, 'navigationLastPage'))">
			<xsl:value-of select="concat($pfx, '  ''navigationLastPage'':&#x0a;')"/>
			<xsl:value-of select="concat($pfx, '    $ref: ''',$commonDefsFileName,'#/components/schemas/httpHeaders/response/navigationLastPage''&#x0a;')"/>
		</xsl:if>

		<xsl:if test="not(contains($excludeHeaders, 'navigationPage'))">
			<xsl:value-of select="concat($pfx, '  ''navigationPage'':&#x0a;')"/>
			<xsl:value-of select="concat($pfx, '    $ref: ''',$commonDefsFileName,'#/components/schemas/httpHeaders/response/navigationPage''&#x0a;')"/>
		</xsl:if>

		<xsl:if test="not(contains($excludeHeaders, 'navigationPageSize'))">
			<xsl:value-of select="concat($pfx, '  ''navigationPageSize'':&#x0a;')"/>
			<xsl:value-of select="concat($pfx, '    $ref: ''',$commonDefsFileName,'#/components/schemas/httpHeaders/response/navigationPageSize''&#x0a;')"/>
		</xsl:if>

		<xsl:if test="$produceAllHeaders">
			<xsl:if test="not(contains($excludeHeaders, 'relativeServicePath'))">
				<xsl:value-of select="concat($pfx, '  ''relativeServicePath'':&#x0a;')"/>
				<xsl:value-of select="concat($pfx, '    $ref: ''',$commonDefsFileName,'#/components/schemas/httpHeaders/response/relativeServicePath''&#x0a;')"/>
			</xsl:if>
		</xsl:if>

		<xsl:if test="not(contains($excludeHeaders, 'requestId'))">
			<xsl:value-of select="concat($pfx, '  ''requestId'':&#x0a;')"/>
			<xsl:value-of select="concat($pfx, '    $ref: ''',$commonDefsFileName,'#/components/schemas/httpHeaders/response/requestId''&#x0a;')"/>
		</xsl:if>
				
		<xsl:if test="not(contains($excludeHeaders, 'responseAction'))">
			<xsl:value-of select="concat($pfx, '  ''responseAction'':&#x0a;')"/>
			<xsl:value-of select="concat($pfx, '    $ref: ''',$commonDefsFileName,'#/components/schemas/httpHeaders/response/responseAction''&#x0a;')"/>
		</xsl:if>
		
		<xsl:if test="$produceAllHeaders">
			<xsl:if test="not(contains($excludeHeaders, 'serviceType'))">
				<xsl:value-of select="concat($pfx, '  ''serviceType'':&#x0a;')"/>
				<xsl:value-of select="concat($pfx, '    $ref: ''',$commonDefsFileName,'#/components/schemas/httpHeaders/response/serviceType''&#x0a;')"/>
			</xsl:if>
		
			<xsl:if test="not(contains($excludeHeaders, 'serviceSubType'))">
				<xsl:value-of select="concat($pfx, '  ''serviceSubType'':&#x0a;')"/>
				<xsl:value-of select="concat($pfx, '    $ref: ''',$commonDefsFileName,'#/components/schemas/httpHeaders/response/serviceSubType''&#x0a;')"/>
			</xsl:if>

			<xsl:if test="not(contains($excludeHeaders, 'timestamp'))">
				<xsl:value-of select="concat($pfx, '  ''timestamp'':&#x0a;')"/>
				<xsl:value-of select="concat($pfx, '    $ref: ''',$commonDefsFileName,'#/components/schemas/httpHeaders/response/timestamp''&#x0a;')"/>
			</xsl:if>
			
			<xsl:if test="not(contains($excludeHeaders, 'vary'))">
				<xsl:value-of select="concat($pfx, '  ''vary'':&#x0a;')"/>
				<xsl:value-of select="concat($pfx, '    $ref: ''',$commonDefsFileName,'#/components/schemas/httpHeaders/response/vary''&#x0a;')"/>
			</xsl:if>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="specgen:DataObjects" mode="paths">
		<xsl:text>paths:&#x0a;</xsl:text>
		<xsl:apply-templates select=".//specgen:DataObject" mode="paths"/>
	</xsl:template>   
	
	<!-- ======================================= -->
	<!-- Section with HTTP Operation Definition  -->
	<!-- ======================================= -->
        <xsl:template match="specgen:DataObject" mode="paths">
                <!-- NN 20231102 Insert commas around @name, for delimiter detection, to prevent spurious substring match -->
                <xsl:variable name="commadelim_name">
                        <xsl:value-of select="concat(',', @name,',')"/>
                </xsl:variable>
                <xsl:if test="xfn:containsOrEmpty($sifObjectList1, $commadelim_name)">
			<xsl:variable name="excludeOps" select="specgen:OpenAPI/specgen:ExcludeOperations"/>
	
			<!--xsl:variable name="additionalSegments" select="string-join(specgen:OpenAPI/specgen:UrlSegments/specgen:UrlSegment/specgen:Name, '/')"-->
			<xsl:variable name="additionalSegments">
   				<xsl:value-of select="specgen:OpenAPI/specgen:UrlSegments/specgen:UrlSegment/specgen:Name" separator="/" />
			</xsl:variable>

			<xsl:variable name="objectBasePath">
			    <xsl:if test="xfn:empty($additionalSegments)">
			        <xsl:value-of select="concat(@name, 's')"/>
			    </xsl:if>
			    <xsl:if test="not(xfn:empty($additionalSegments))">
			        <xsl:value-of select="concat(@name, 's/', $additionalSegments)"/>
			    </xsl:if>
			</xsl:variable>
			
			<xsl:variable name="additionalSegments" >
   				<xsl:value-of select="specgen:OpenAPI/specgen:UrlSegments/specgen:UrlSegment/specgen:Name" separator="/" />
			</xsl:variable>
	
			<!-- Check if end-point is excluded entirely -->
			<xsl:if test="not(contains($excludeOps,'ALL'))">
				<xsl:text>  # //////////////////////////////////////////////&#x0a;</xsl:text>
				<xsl:value-of select="concat('  # // ', $objectBasePath, ' Endpoints &#x0a;')"/>
				<xsl:text>  # //////////////////////////////////////////////&#x0a;</xsl:text>
				
				<!-- Check if batch end-points are excluded -->
				<xsl:if test="not(contains($excludeOps,'all-batch'))">
					<xsl:value-of select="concat('  /', $objectBasePath, ':&#x0a;')"/>
		
					<xsl:if test="not(contains($excludeOps,'get-batch'))">
						<!-- ================================ -->
						<!-- GET - Multiple: .../SchoolInfos  -->
						<!-- ================================ -->
						<xsl:text>    get:&#x0a;</xsl:text>
						<xsl:value-of select="concat('      tags:&#x0a;      - ', $q, @name, $q, '&#x0a;')"/>
						<xsl:value-of select="concat('      summary: Default operation to get a list of all available ', @name, 's&#x0a;')"/>
						<xsl:value-of select="concat('      description: Default operation to get a list of all available ', @name, 's&#x0a;')"/>
						<xsl:value-of select="concat('      operationId: get', @name, 's&#x0a;')"/>
		
						<xsl:text>      parameters:&#x0a;</xsl:text>
		
						<xsl:apply-templates select=".//specgen:UrlSegments" mode="additionalSegments"/>
		
						<xsl:apply-templates select="." mode="addQueryParamterList">
							<xsl:with-param name="excludeQueryParamters">
								<xsl:value-of select="specgen:OpenAPI/specgen:GetBatch/specgen:ExcludeQueryParams"/>
							</xsl:with-param>
						</xsl:apply-templates>
		
						<xsl:apply-templates select="." mode="addRequestHTTPHeaderList">
							<xsl:with-param name="excludeHTTPHeaders">
								<xsl:value-of select="concat(specgen:OpenAPI/specgen:GetBatch/specgen:ExcludeRequestHTTPHeaders,
								                     ',connectionId, content-encoding, content-type, content-profile, dataPrivacyMarkerBatchPutRequest, methodOverridePut, methodOverridePost, mustUseAdvisory, serviceSubType, replacement')"/>
							</xsl:with-param>
						</xsl:apply-templates>
		
						<xsl:apply-templates select="." mode="responsesList">
							<xsl:with-param name="includeAccepted">
								<xsl:value-of select="xfn:emptyOrTrue(specgen:OpenAPI/specgen:GetBatch/specgen:DelayedSupported)"/>
							</xsl:with-param>
						</xsl:apply-templates>
		
						<xsl:apply-templates select="." mode="addErrorCodeList">
							<xsl:with-param name="inlcudeErrorCodes">400, 401, 403, 410, 413, 415, 500, 501, 503</xsl:with-param>
							<xsl:with-param name="excludeErrorCodes">
								<xsl:value-of select="specgen:OpenAPI/specgen:GetBatch/specgen:ExcludeErrorCodes"/>
							</xsl:with-param>
						</xsl:apply-templates>
					</xsl:if>
		
					<xsl:if test="not(contains($excludeOps,'head-batch'))">
						<!-- ======================= -->
						<!-- HEAD - .../SchoolInfos  -->
						<!-- ======================= -->
						<xsl:text>    head:&#x0a;</xsl:text>
						<xsl:value-of select="concat('      tags:&#x0a;      - ', $q, @name, $q, '&#x0a;')"/>
						<xsl:value-of select="concat('      summary: Get HEAD info for ', @name, 's.&#x0a;')"/>
						<xsl:value-of select="concat('      description: Get HEAD info for ', @name, 's. Returns all HTTP Headers but no payload, otherwise it works like HTTP GET. &#x0a;')"/>
						<xsl:value-of select="concat('      operationId: head', @name, 's&#x0a;')"/>
		
						<xsl:text>      parameters:&#x0a;</xsl:text>

						<xsl:apply-templates select=".//specgen:UrlSegments" mode="additionalSegments"/>

						<xsl:apply-templates select="." mode="addRequestHTTPHeaderList">
							<xsl:with-param name="excludeHTTPHeaders">
								<xsl:value-of select="concat(specgen:OpenAPI/specgen:HeadBatch/specgen:ExcludeRequestHTTPHeaders,
								                     ',connectionId, content-encoding, content-type, content-profile, dataPrivacyMarkerBatchPutRequest, methodOverridePut, methodOverridePost, mustUseAdvisory, serviceSubType, replacement')"/>
							</xsl:with-param>
						</xsl:apply-templates>
		
						<!-- Need to list HTTP Errors specifically without  payload because HTTP Head doesn't have payloads. -->
						<xsl:text>      responses:&#x0a;</xsl:text>
						<xsl:text>        '200':&#x0a;</xsl:text>
						<xsl:text>          description: Operation succeeded. No payload returned for HTTP HEAD.&#x0a;</xsl:text>

						<!-- Response Headers -->
						<xsl:apply-templates select="." mode="addResponseHeaders">
							<xsl:with-param name="pfx"><xsl:text>          </xsl:text></xsl:with-param>
							<xsl:with-param name="excludeHeaders">
								<xsl:value-of select="concat(specgen:OpenAPI/specgen:HeadBatch/specgen:ExcludeResponseHTTPHeaders, ',changesSinceMarkerGet, dataPrivacyMarkerBatchPutResponse, serviceSubType')"/>
							</xsl:with-param>
						</xsl:apply-templates>
		
						<xsl:text>        '401':&#x0a;</xsl:text>
						<xsl:text>          description: Authorisation failed.&#x0a;</xsl:text>
	
						<!-- Response Headers -->
						<xsl:apply-templates select="." mode="addResponseHeaders">
							<xsl:with-param name="pfx"><xsl:text>          </xsl:text></xsl:with-param>
							<xsl:with-param name="excludeHeaders">
								<xsl:value-of select="concat(specgen:OpenAPI/specgen:HeadBatch/specgen:ExcludeResponseHTTPHeaders, ',changesSinceMarkerGet,changesSinceMarkerHead,dataPrivacyMarkerBatchPutResponse,navigationCount,navigationId,navigationLastPage,navigationPageSize,navigationLastPageSize,serviceSubType')"/>
							</xsl:with-param>
						</xsl:apply-templates>
					</xsl:if>
		
					<xsl:if test="not(contains($excludeOps,'put-batch'))">
						<!-- ================================ -->
						<!-- PUT - Multiple: .../SchoolInfos  -->
						<!-- ================================ -->
						<xsl:text>    put:&#x0a;</xsl:text>
						<xsl:value-of select="concat('      tags:&#x0a;      - ', $q, @name, $q, '&#x0a;')"/>
						<xsl:value-of select="concat('      summary: Default operation to update or delete multiple ', @name, '&#x0a;')"/>
						<xsl:value-of select="concat('      description: Default operation to update or delete multiple ', @name, '&#x0a;')"/>
		
						<xsl:apply-templates select="." mode="requestBodyList">
							<xsl:with-param name="operationId" select="concat('update', @name, 's')"/>
							<xsl:with-param name="schemaId">update</xsl:with-param>
						</xsl:apply-templates>
		
						<xsl:text>      parameters:&#x0a;</xsl:text>

						<xsl:apply-templates select=".//specgen:UrlSegments" mode="additionalSegments"/>

						<xsl:apply-templates select="." mode="addRequestHTTPHeaderList">
							<xsl:with-param name="excludeHTTPHeaders">
								<xsl:value-of select="concat(specgen:OpenAPI/specgen:PutBatch/specgen:ExcludeRequestHTTPHeaders,
								                     ',connectionId, dataPrivacyMarkerStd, methodOverridePost, mustUseAdvisory, navigationId, navigationPage, navigationPageSize, queryIntention, serviceSubType')"/>
							</xsl:with-param>
						</xsl:apply-templates>
		
						<xsl:apply-templates select="." mode="updateListResponses">
							<xsl:with-param name="includeAccepted">
								<xsl:value-of select="xfn:emptyOrTrue(specgen:OpenAPI/specgen:PutBatch/specgen:DelayedSupported)"/>
							</xsl:with-param>
						</xsl:apply-templates>
		
						<xsl:apply-templates select="." mode="addErrorCodeList">
							<xsl:with-param name="inlcudeErrorCodes">400, 401, 403, 412, 415, 500, 501, 503</xsl:with-param>
							<xsl:with-param name="excludeErrorCodes">
								<xsl:value-of select="specgen:OpenAPI/specgen:PutBatch/specgen:ExcludeErrorCodes"/>
							</xsl:with-param>
						</xsl:apply-templates>
					</xsl:if>
		
					<xsl:if test="not(contains($excludeOps,'post-batch'))">
						<!-- =============================== -->
						<!-- POST - Multiple: .../SchoolInfos  -->
						<!-- =============================== -->
						<xsl:text>    post:&#x0a;</xsl:text>
						<xsl:value-of select="concat('      tags:&#x0a;      - ', $q, @name, $q, '&#x0a;')"/>
						
						<xsl:if test="xfn:emptyOrTrue(specgen:OpenAPI/specgen:PostBatch/specgen:QBESupported)">
							<xsl:value-of select="concat('      summary: Default operation to create multiple ', @name, 's or query by example (QBE).&#x0a;')"/>
							<xsl:value-of select="concat('      description: Default operation to create multiple ', @name, 's or query by example (QBE).&#x0a;')"/>
						</xsl:if>
						<xsl:if test="not(xfn:emptyOrTrue(specgen:OpenAPI/specgen:PostBatch/specgen:QBESupported))">
							<xsl:value-of select="concat('      summary: Default operation to create multiple ', @name, 's.&#x0a;')"/>
							<xsl:value-of select="concat('      description: Default operation to create multiple ', @name, 's.&#x0a;')"/>
						</xsl:if>
		
						<xsl:apply-templates select="." mode="requestBodyList">
							<xsl:with-param name="operationId" select="concat('create', @name, 's')"/>
							<xsl:with-param name="schemaId">create</xsl:with-param>
						</xsl:apply-templates>
		
						<xsl:text>      parameters:&#x0a;</xsl:text>

						<xsl:apply-templates select=".//specgen:UrlSegments" mode="additionalSegments"/>

						<xsl:apply-templates select="." mode="addRequestHTTPHeaderList">
							<xsl:with-param name="excludeHTTPHeaders">
								<xsl:value-of select="concat(specgen:OpenAPI/specgen:PostBatch/specgen:ExcludeRequestHTTPHeaders,
								                     ',connectionId, dataPrivacyMarkerBatchPutRequest, methodOverridePut, navigationId, navigationPage, navigationPageSize, queryIntention, serviceSubType, replacement')"/>
							</xsl:with-param>
						</xsl:apply-templates>
		
						<xsl:apply-templates select="." mode="createListResponses">
							<xsl:with-param name="includeAccepted">
								<xsl:value-of select="xfn:emptyOrTrue(specgen:OpenAPI/specgen:PostBatch/specgen:DelayedSupported)"/>
							</xsl:with-param>
							<xsl:with-param name="qbeSupported">
								<xsl:value-of select="xfn:emptyOrTrue(specgen:OpenAPI/specgen:PostBatch/specgen:QBESupported)"/>
							</xsl:with-param>
						</xsl:apply-templates>
		
						<xsl:apply-templates select="." mode="addErrorCodeList">
							<xsl:with-param name="inlcudeErrorCodes">400, 401, 403, 409, 412, 415, 500, 501, 503</xsl:with-param>
							<xsl:with-param name="excludeErrorCodes">
								<xsl:value-of select="specgen:OpenAPI/specgen:PostBatch/specgen:ExcludeErrorCodes"/>
							</xsl:with-param>
						</xsl:apply-templates>
					</xsl:if>

				</xsl:if>
				
				<xsl:if test="not(contains($excludeOps,'post-single')) and not(contains($excludeOps,'all-single'))">
					<!-- ========================================== -->
					<!-- POST - Single: .../SchoolInfos/SchoolInfo  -->
					<!-- ========================================== -->
					<xsl:value-of select="concat('  /', $objectBasePath, '/', @name, ':&#x0a;')"/>
					<xsl:text>    post:&#x0a;</xsl:text>
					<xsl:value-of select="concat('      tags:&#x0a;      - ', $q, @name, $q, '&#x0a;')"/>
					<xsl:value-of select="concat('      summary: Default operation to create a single ', @name, '&#x0a;')"/>
					<xsl:value-of select="concat('      description: Default operation to create a single ', @name, '&#x0a;')"/>
					<xsl:apply-templates select="." mode="requestBody">
						<xsl:with-param name="operationId" select="concat('create', @name)"/>
						<xsl:with-param name="schemaId">create</xsl:with-param>
					</xsl:apply-templates>
	
					<xsl:text>      parameters:&#x0a;</xsl:text>

					<xsl:apply-templates select=".//specgen:UrlSegments" mode="additionalSegments"/>

					<xsl:apply-templates select="." mode="addRequestHTTPHeaderList">
						<xsl:with-param name="excludeHTTPHeaders">
							<xsl:value-of select="concat(specgen:OpenAPI/specgen:PostSingle/specgen:ExcludeRequestHTTPHeaders,
                                                         ',connectionId, dataPrivacyMarkerBatchPutRequest, methodOverridePut, methodOverridePost, navigationId, navigationPage, navigationPageSize, queueId, queryIntention, serviceSubType, replacement, requestType')"/>
						</xsl:with-param>
					</xsl:apply-templates>
	
					<xsl:apply-templates select="." mode="responsesSingle">
						<xsl:with-param name="schemaId">create</xsl:with-param>
						<xsl:with-param name="returnCode">201</xsl:with-param>
					</xsl:apply-templates>
	
					<xsl:apply-templates select="." mode="addErrorCodeList">
						<xsl:with-param name="inlcudeErrorCodes">400, 401, 403, 409, 412, 415, 500, 501, 503</xsl:with-param>
						<xsl:with-param name="excludeErrorCodes">
							<xsl:value-of select="specgen:OpenAPI/specgen:PostSingle/specgen:ExcludeErrorCodes"/>
						</xsl:with-param>
					</xsl:apply-templates>
				</xsl:if>
	
				<!-- Check if single end-points are excluded -->
				<xsl:if test="not(contains($excludeOps,'all-single'))">
					<xsl:if test="specgen:Key">
						<xsl:value-of select="concat('  /', $objectBasePath, '/{', translate(specgen:Key[1], '@', ''), '}:&#x0a;')"/>
		
						<xsl:if test="not(contains($excludeOps,'put-single'))">
							<!-- ====================================== -->
							<!-- PUT - Single: .../SchoolInfos/{refId}  -->
							<!-- ====================================== -->
							<xsl:text>    put:&#x0a;</xsl:text>
							<xsl:value-of select="concat('      tags:&#x0a;      - ', $q, @name, $q, '&#x0a;')"/>
							<xsl:value-of select="concat('      summary: Default operation to update a single ', @name, '&#x0a;')"/>
							<xsl:value-of select="concat('      description: Default operation to update a single ', @name, '&#x0a;')"/>
							<xsl:value-of select="concat('      parameters:','&#x0a;')"/>
							
							<xsl:apply-templates select=".//specgen:UrlSegments" mode="additionalSegments"/>

							<!-- Add the {id} path parameter -->
							<xsl:value-of select="concat('      - name: ', translate(specgen:Key[1], '@', ''), '&#x0a;')"/>
							<xsl:text>        in: path&#x0a;        description: >-&#x0a;          </xsl:text>
							<xsl:apply-templates select="specgen:Item[specgen:Element=current()/specgen:Key[1]]/specgen:Description"/><xsl:text>&#x0a;</xsl:text>
							<xsl:text>        required: true&#x0a;</xsl:text>
							<xsl:text>        schema:&#x0a;</xsl:text>
							<xsl:text>          type: string&#x0a;</xsl:text>
		
							<xsl:apply-templates select="." mode="addRequestHTTPHeaderList">
								<xsl:with-param name="excludeHTTPHeaders">
									<xsl:value-of select="concat(specgen:OpenAPI/specgen:PutSingle/specgen:ExcludeRequestHTTPHeaders,
							                     ',connectionId, dataPrivacyMarkerBatchPutRequest, methodOverridePut, methodOverridePost, mustUseAdvisory, navigationId, navigationPage, navigationPageSize, queueId, queryIntention, serviceSubType, requestType')"/>
								</xsl:with-param>
							</xsl:apply-templates>
		
							<xsl:apply-templates select="." mode="requestBody">
								<xsl:with-param name="operationId" select="concat('update', @name)"/>
								<xsl:with-param name="schemaId">update</xsl:with-param>
							</xsl:apply-templates>
		
							<xsl:apply-templates select="." mode="responsesSingle">
								<xsl:with-param name="schemaId">update</xsl:with-param>
								<xsl:with-param name="returnCode">200</xsl:with-param>
							</xsl:apply-templates>
		
							<xsl:apply-templates select="." mode="addErrorCodeList">
								<xsl:with-param name="inlcudeErrorCodes">400, 401, 403, 404, 412, 415, 500, 501, 503</xsl:with-param>
								<xsl:with-param name="excludeErrorCodes">
									<xsl:value-of select="specgen:OpenAPI/specgen:PutSingle/specgen:ExcludeErrorCodes"/>
								</xsl:with-param>
							</xsl:apply-templates>
						</xsl:if>
		
						<xsl:if test="not(contains($excludeOps,'get-single'))">
							<!-- ====================================== -->
							<!-- GET - Single: .../SchoolInfos/{refId}  -->
							<!-- ====================================== -->
							<xsl:text>    get:&#x0a;</xsl:text>
							<xsl:value-of select="concat('      tags:&#x0a;      - ', $q, @name, $q, '&#x0a;')"/>
							<xsl:value-of select="concat('      summary: Default operation to get a single ', @name, '&#x0a;')"/>
							<xsl:value-of select="concat('      description: Default operation to get a single ', @name, '&#x0a;')"/>
							<xsl:value-of select="concat('      operationId: get', @name, '&#x0a;')"/>

							<xsl:value-of select="concat('      parameters:','&#x0a;')"/>
							
							<xsl:apply-templates select=".//specgen:UrlSegments" mode="additionalSegments"/>

							<!-- Add the {id} path parameter -->
							<xsl:value-of select="concat('      - name: ', translate(specgen:Key[1], '@', ''), '&#x0a;')"/>
							<xsl:text>        in: path&#x0a;        description: >-&#x0a;          </xsl:text>
							<xsl:apply-templates select="specgen:Item[specgen:Element=current()/specgen:Key[1]]/specgen:Description"/><xsl:text>&#x0a;</xsl:text>
							<xsl:text>        required: true&#x0a;</xsl:text>
							<xsl:text>        schema:&#x0a;</xsl:text>
							<xsl:text>          type: string&#x0a;</xsl:text>
		
							<xsl:apply-templates select="." mode="addRequestHTTPHeaderList">
								<xsl:with-param name="excludeHTTPHeaders">
									<xsl:value-of select="concat(specgen:OpenAPI/specgen:GetSingle/specgen:ExcludeRequestHTTPHeaders,
							                     ',connectionId, content-encoding, content-type, content-profile, dataPrivacyMarkerBatchPutRequest, methodOverridePut, methodOverridePost, mustUseAdvisory, navigationId, navigationPage, navigationPageSize, queueId, queryIntention, serviceSubType, requestType, replacement')"/>
								</xsl:with-param>
							</xsl:apply-templates>
		
							<xsl:apply-templates select="." mode="responsesSingle">
								<xsl:with-param name="schemaId">create</xsl:with-param>
								<xsl:with-param name="returnCode">200</xsl:with-param>		
							</xsl:apply-templates>
		
							<xsl:apply-templates select="." mode="addErrorCodeList">
								<xsl:with-param name="inlcudeErrorCodes">400, 401, 403, 404, 405, 415, 500, 501, 503</xsl:with-param>
								<xsl:with-param name="excludeErrorCodes">
									<xsl:value-of select="specgen:OpenAPI/specgen:GetSingle/specgen:ExcludeErrorCodes"/>
								</xsl:with-param>
							</xsl:apply-templates>
						</xsl:if>
		
						<xsl:if test="not(contains($excludeOps,'delete-single'))">
							<!-- ========================================= -->
							<!-- DELETE - Single: .../SchoolInfos/{refId}  -->
							<!-- ========================================= -->
							<xsl:text>    delete:&#x0a;</xsl:text>
							<xsl:value-of select="concat('      tags:&#x0a;      - ', $q, @name, $q, '&#x0a;')"/>
							<xsl:value-of select="concat('      summary: Default operation to delete a single ', @name, '&#x0a;')"/>
							<xsl:value-of select="concat('      description: Default operation to delete a single ', @name, '&#x0a;')"/>
							<xsl:value-of select="concat('      operationId: delete', @name, '&#x0a;')"/>

							<xsl:value-of select="concat('      parameters:','&#x0a;')"/>
							
							<xsl:apply-templates select=".//specgen:UrlSegments" mode="additionalSegments"/>

							<!-- Add the {id} path parameter -->
							<xsl:value-of select="concat('      - name: ', translate(specgen:Key[1], '@', ''), '&#x0a;')"/>

							<xsl:text>        in: path&#x0a;        description: >-&#x0a;          </xsl:text>
							<xsl:apply-templates select="specgen:Item[specgen:Element=current()/specgen:Key[1]]/specgen:Description"/><xsl:text>&#x0a;</xsl:text>
							<xsl:text>        required: true&#x0a;</xsl:text>
							<xsl:text>        schema:&#x0a;</xsl:text>
							<xsl:text>          type: string&#x0a;</xsl:text>
		
							<xsl:apply-templates select="." mode="addRequestHTTPHeaderList">
								<xsl:with-param name="excludeHTTPHeaders">
									<xsl:value-of select="concat(specgen:OpenAPI/specgen:DeleteSingle/specgen:ExcludeRequestHTTPHeaders,
							                     ',connectionId, content-encoding, content-type, content-profile, dataPrivacyMarkerStd, dataPrivacyMarkerBatchPutRequest, methodOverridePut, methodOverridePost, mustUseAdvisory, navigationId, navigationPage, navigationPageSize, queueId, queryIntention, requestType, replacement, serviceSubType')"/>
								</xsl:with-param>
							</xsl:apply-templates>
		
							<xsl:text>      responses:&#x0a;</xsl:text>
							<xsl:text>        '204':&#x0a;</xsl:text>
							<xsl:text>          description: successful operation&#x0a;</xsl:text>
		
							<!-- Response Headers -->
							<xsl:apply-templates select="." mode="addResponseHeaders">
								<xsl:with-param name="pfx"><xsl:text>          </xsl:text></xsl:with-param>
								<xsl:with-param name="excludeHeaders">
									<xsl:value-of select="xfn:conditinalConcat(not($produceAllHeaders),'changesSinceMarkerGet,changesSinceMarkerHead, dataPrivacyMarkerStd, dataPrivacyMarkerBatchPutResponse, navigationCount,navigationId,navigationLastPage,navigationPage,navigationPageSize',',requestId')"/>
								</xsl:with-param>
							</xsl:apply-templates>
	
							<xsl:apply-templates select="." mode="addErrorCodeList">
								<xsl:with-param name="inlcudeErrorCodes">401, 403, 404, 500, 501, 503</xsl:with-param>
								<xsl:with-param name="excludeErrorCodes">
									<xsl:value-of select="specgen:OpenAPI/specgen:DeleteSingle/specgen:ExcludeErrorCodes"/>
								</xsl:with-param>
							</xsl:apply-templates>
						</xsl:if>
					</xsl:if>
				</xsl:if>

				<!-- Check if admin directives shall be produced by the specification. -->
				<xsl:if test="$produceAdminDirectives">
				
					<!-- Check if batch end-points are excluded -->
					<xsl:if test="not(contains($excludeOps,'all-batch'))">
					
						<!-- Check if a specific object/functional service excludes admin directives. -->
						<xsl:if test="not(contains($excludeOps, 'adminDirective'))">
							<xsl:value-of select="concat('  /', $objectBasePath, '/adminDirectives', ':&#x0a;')"/>

							<!-- ======================================================= -->
							<!-- GET - AdminDirectives: .../SchoolInfos/adminDirectives  -->
							<!-- ======================================================= -->
							<xsl:text>    get:&#x0a;</xsl:text>
							<xsl:value-of select="concat('      tags:&#x0a;      - ', $q, @name, $q, '&#x0a;')"/>
							<xsl:value-of select="concat('      summary: Retrieve pending ''Admin Directive'' instructions for ', @name, 's&#x0a;')"/>
							<xsl:value-of select="concat('      description: Retrieve pending ''Admin Directives'' via the ''Changes Since'' mechanism for ', @name, 's&#x0a;')"/>
							<xsl:value-of select="concat('      operationId: get', @name, '-adminDirectives&#x0a;')"/>
			
							<xsl:text>      parameters:&#x0a;</xsl:text>
							
							<xsl:apply-templates select=".//specgen:UrlSegments" mode="additionalSegments"/>

							<!-- Only the Changes Since marker is supported for admin directives. -->
							<xsl:apply-templates select="." mode="addQueryParamterList">
								<xsl:with-param name="excludeQueryParamters">order, where</xsl:with-param>
							</xsl:apply-templates>
							
							<xsl:apply-templates select="." mode="addRequestHTTPHeaderList">
								<xsl:with-param name="excludeHTTPHeaders">
									<xsl:value-of select="concat(specgen:OpenAPI/specgen:GetBatch/specgen:ExcludeRequestHTTPHeaders,
									                     ',connectionId, content-encoding, content-type, content-profile, dataPrivacyMarkerBatchPutRequest, methodOverridePut, methodOverridePost, mustUseAdvisory, replacement')"/>
								</xsl:with-param>
							</xsl:apply-templates>
			
							<xsl:apply-templates select="." mode="responsesList">
							    <!--  Batch is not allowed for admin directive, so the 'Accepted' header isn't either -->
								<xsl:with-param name="includeAccepted" select="false()"/>
								<xsl:with-param name="isAdminDirective" select="true()"/>
							</xsl:apply-templates>
			
							<xsl:apply-templates select="." mode="addErrorCodeList">
								<xsl:with-param name="inlcudeErrorCodes">400, 401, 403, 410, 413, 415, 500, 501, 503</xsl:with-param>
								<xsl:with-param name="excludeErrorCodes"/>
							</xsl:apply-templates>
	
							<!-- ======================================================== -->
							<!-- HEAD - AdminDirectives: .../SchoolInfos/adminDirectives  -->
							<!-- ======================================================== -->
							<xsl:text>    head:&#x0a;</xsl:text>
							<xsl:value-of select="concat('      tags:&#x0a;      - ', $q, @name, $q, '&#x0a;')"/>
							<xsl:value-of select="concat('      summary: Get HEAD info for ''Admin Directives'' for ', @name, 's&#x0a;')"/>
							<xsl:value-of select="concat('      description: Get HEAD info for ''Admin Directives'' for ', @name, 's. Returns all HTTP Headers but no payload, otherwise it works like HTTP GET. &#x0a;')"/>
							<xsl:value-of select="concat('      operationId: head', @name, 'adminDirectives&#x0a;')"/>
			
							<xsl:text>      parameters:&#x0a;</xsl:text>
							
							<xsl:apply-templates select=".//specgen:UrlSegments" mode="additionalSegments"/>
							
							<xsl:apply-templates select="." mode="addRequestHTTPHeaderList">
								<xsl:with-param name="excludeHTTPHeaders">
									<xsl:value-of select="concat(specgen:OpenAPI/specgen:HeadBatch/specgen:ExcludeRequestHTTPHeaders,
									                     ',connectionId, content-encoding, content-type, content-profile, dataPrivacyMarkerBatchPutRequest, methodOverridePut, methodOverridePost, mustUseAdvisory, replacement')"/>
								</xsl:with-param>
							</xsl:apply-templates>
			
							<!-- Need to list HTTP Errors specifically without  payload because HTTP Head doesn't have payloads. -->
							<xsl:text>      responses:&#x0a;</xsl:text>
							<xsl:text>        '200':&#x0a;</xsl:text>
							<xsl:text>          description: Operation succeeded. No payload returned for HTTP HEAD.&#x0a;</xsl:text>
	
							<!-- Response Headers -->
							<xsl:apply-templates select="." mode="addResponseHeaders">
								<xsl:with-param name="pfx"><xsl:text>          </xsl:text></xsl:with-param>
								<xsl:with-param name="excludeHeaders">
									<xsl:value-of select="concat(specgen:OpenAPI/specgen:HeadBatch/specgen:ExcludeResponseHTTPHeaders, ',changesSinceMarkerGet, dataPrivacyMarkerBatchPutResponse')"/>
								</xsl:with-param>
							</xsl:apply-templates>
			
							<xsl:text>        '401':&#x0a;</xsl:text>
							<xsl:text>          description: Authorisation failed.&#x0a;</xsl:text>
		
							<!-- Response Headers -->
							<xsl:apply-templates select="." mode="addResponseHeaders">
								<xsl:with-param name="pfx"><xsl:text>          </xsl:text></xsl:with-param>
								<xsl:with-param name="excludeHeaders">
									<xsl:value-of select="concat(specgen:OpenAPI/specgen:HeadBatch/specgen:ExcludeResponseHTTPHeaders, ',changesSinceMarkerGet,changesSinceMarkerHead,dataPrivacyMarkerBatchPutResponse,navigationCount,navigationId,navigationLastPage,navigationPageSize,navigationLastPageSize')"/>
								</xsl:with-param>
							</xsl:apply-templates>
						</xsl:if>
					</xsl:if>
				</xsl:if>

			</xsl:if>
			
		    <!-- ========================================= -->
		    <!-- Add other static paths for this endpoint. -->
		    <!-- ========================================= -->
		  	<xsl:apply-templates select=".//specgen:Paths" mode="additionalPaths"/>
		  	
			<xsl:text>&#x0a;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="specgen:UrlSegments" mode="additionalSegments">
		<xsl:apply-templates select=".//specgen:UrlSegment" mode="additionalSegment"/>
	</xsl:template> 
  
	<xsl:template match="specgen:UrlSegment" mode="additionalSegment">
		<!-- Only segments of type 'variable' are of interest. Since 'variable' is assumed default we can check for NOT constant -->
		<xsl:if test="(specgen:Type = 'variable') or xfn:empty(specgen:Type)">
		    <xsl:value-of select="concat('      - name: ', translate(specgen:Name, '{}', ''), '&#x0a;')"/>
		    <xsl:value-of select="concat('        in: path', '&#x0a;')"/>
		    <xsl:value-of select="concat('        description: >-', '&#x0a;')"/>
		    <xsl:value-of select="concat('          ', specgen:Description,'&#x0a;')"/>
		    <xsl:value-of select="concat('        required: true', '&#x0a;')"/>
		    <xsl:value-of select="concat('        schema:', '&#x0a;')"/>
		    <xsl:value-of select="concat('          type: string', '&#x0a;')"/>
		</xsl:if>
	</xsl:template> 

	<xsl:template match="specgen:Paths" mode="additionalPaths">
		<xsl:apply-templates select=".//specgen:Path" mode="additionalPaths"/>
	</xsl:template> 
  
	<xsl:template match="specgen:Path" mode="additionalPaths">
		<xsl:value-of select="concat('  ', specgen:URI, ':&#x0a;')"/>
		<xsl:value-of select="concat('    $ref: ''', specgen:Ref, '''&#x0a;')"/>
	</xsl:template> 

    <xsl:template match="specgen:DataObject" mode="requestBody">
		<xsl:param name="operationId"/>
		<xsl:param name="schemaId"/>
		<xsl:value-of select="concat('      operationId: ', $operationId, '&#x0a;')"/>
		<xsl:text>      requestBody:&#x0a;</xsl:text>
                <xsl:value-of select="concat('        $ref: ''#/components/requestBodies/', $schemaId, @name, '''&#x0a;')"/>
	</xsl:template>

    <xsl:template match="specgen:DataObject" mode="requestBodyList">
		<xsl:param name="operationId"/>
		<xsl:param name="schemaId"/>
		<xsl:value-of select="concat('      operationId: ', $operationId, '&#x0a;')"/>
		<xsl:text>      requestBody:&#x0a;</xsl:text>
                <xsl:value-of select="concat('        $ref: ''#/components/requestBodies/', $schemaId, @name, 's''&#x0a;')"/>
	</xsl:template>

    <xsl:template match="specgen:DataObject" mode="responsesSingle">
		<xsl:param name="schemaId"/>
		<xsl:param name="returnCode"/>
		
		<xsl:text>      responses:&#x0a;</xsl:text>
		<xsl:value-of select="concat('        ''', $returnCode , ''':&#x0a;')"/>
                <xsl:value-of select="concat('          $ref: ''#/components/responses/', $schemaId, @name, '''&#x0a;')"/>
	</xsl:template>

    <xsl:template match="specgen:DataObject" mode="responsesList">
		<xsl:param name="includeAccepted" as="xs:boolean"/>
		<xsl:param name="isAdminDirective" as="xs:boolean" select="false()"/>
		
		<xsl:text>      responses:&#x0a;</xsl:text>
        <xsl:text>        '200':&#x0a;</xsl:text>
        
        <xsl:if test="not($isAdminDirective)">
          <xsl:value-of select="concat('          $ref: ''#/components/responses/create', @name, 's''&#x0a;')"/>
		</xsl:if>
        <xsl:if test="$isAdminDirective">
			<xsl:value-of select="concat('          $ref: ''',$commonDefsFileName,'#/components/schemas/adminDirectiveResponse/adminDirectives', '''&#x0a;')"/>
		</xsl:if>
		
		<xsl:if test="$includeAccepted">
            <xsl:text>        '202':&#x0a;</xsl:text>
            <xsl:text>          description: Accepted. Returned for DELAYED requests. No payload.&#x0a;</xsl:text>
		</xsl:if>
	</xsl:template>

    <!-- ================================ -->
    <!-- Template: Batch PUT Response. -->
    <!-- ================================ -->
    <xsl:template match="specgen:DataObject" mode="updateListResponses">
		<xsl:param name="includeAccepted" as="xs:boolean"/>
		<xsl:text>      responses:&#x0a;</xsl:text>
		<xsl:value-of select="concat('        ''', '200', '''', ':&#x0a;')"/>
		<xsl:value-of select="concat('          $ref: ', '''', $commonDefsFileName,'#/components/schemas/multipleResponses/batchPutResponse''', '&#x0a;')"/>
		<xsl:if test="$includeAccepted">
            <xsl:text>        '202':&#x0a;</xsl:text>
            <xsl:text>          description: Accepted. Returned for DELAYED requests. No payload.&#x0a;</xsl:text>
		</xsl:if>
	</xsl:template>

    <!-- ================================ -->
    <!-- Template: Batch POST Response. -->
    <!-- ================================ -->
    <xsl:template match="specgen:DataObject" mode="createListResponses">
		<xsl:param name="includeAccepted" as="xs:boolean"/>
		<xsl:param name="qbeSupported" as="xs:boolean"/>
		<xsl:text>      responses:&#x0a;</xsl:text>
		<xsl:value-of select="concat('        ''', '200', '''', ':&#x0a;')"/>
		<xsl:if test="$qbeSupported">
			<xsl:value-of select="concat('          $ref: ', '''', '#/components/responses/create', @name, 'sQBE', '''&#x0a;')"/>
		</xsl:if>
		<xsl:if test="not($qbeSupported)">
			<xsl:value-of select="concat('          $ref: ', '''', $commonDefsFileName,'#/components/schemas/multipleResponses/batchPostResponse''', '&#x0a;')"/>
		</xsl:if>
		<xsl:if test="$includeAccepted">
            <xsl:text>        '202':&#x0a;</xsl:text>
            <xsl:text>          description: Accepted. Returned for DELAYED requests. No payload.&#x0a;</xsl:text>
		</xsl:if>
	</xsl:template>

    <!-- ====================================== -->
    <!-- Template: Listing all possible errors. -->
    <!-- ====================================== -->
    <xsl:template match="specgen:DataObject" mode="addErrorCodeList">
		<xsl:param name="inlcudeErrorCodes"/>
		<xsl:param name="excludeErrorCodes"/>
		
		<xsl:if test="xfn:includeProperty('400', $inlcudeErrorCodes, $excludeErrorCodes)">
			<xsl:apply-templates select="." mode="addErrorCodeRef">
				<xsl:with-param name="errorCode">400</xsl:with-param>
			</xsl:apply-templates>
		</xsl:if>

		<xsl:if test="xfn:includeProperty('401', $inlcudeErrorCodes, $excludeErrorCodes)">
			<xsl:apply-templates select="." mode="addErrorCodeRef">
				<xsl:with-param name="errorCode">401</xsl:with-param>
			</xsl:apply-templates>
		</xsl:if>
		
		<xsl:if test="xfn:includeProperty('403', $inlcudeErrorCodes, $excludeErrorCodes)">
			<xsl:apply-templates select="." mode="addErrorCodeRef">
				<xsl:with-param name="errorCode">403</xsl:with-param>
			</xsl:apply-templates>
		</xsl:if>

		<xsl:if test="xfn:includeProperty('404', $inlcudeErrorCodes, $excludeErrorCodes)">
			<xsl:apply-templates select="." mode="addErrorCodeRef">
				<xsl:with-param name="errorCode">404</xsl:with-param>
			</xsl:apply-templates>
		</xsl:if>
		
		<xsl:if test="xfn:includeProperty('405', $inlcudeErrorCodes, $excludeErrorCodes)">
			<xsl:apply-templates select="." mode="addErrorCodeRef">
				<xsl:with-param name="errorCode">405</xsl:with-param>
			</xsl:apply-templates>
		</xsl:if>
		
		<xsl:if test="xfn:includeProperty('409', $inlcudeErrorCodes, $excludeErrorCodes)">
			<xsl:apply-templates select="." mode="addErrorCodeRef">
				<xsl:with-param name="errorCode">409</xsl:with-param>
			</xsl:apply-templates>
		</xsl:if>
		
		<xsl:if test="xfn:includeProperty('410', $inlcudeErrorCodes, $excludeErrorCodes)">
			<xsl:apply-templates select="." mode="addErrorCodeRef">
				<xsl:with-param name="errorCode">410</xsl:with-param>
			</xsl:apply-templates>
		</xsl:if>
		
		<xsl:if test="xfn:includeProperty('412', $inlcudeErrorCodes, $excludeErrorCodes)">
			<xsl:apply-templates select="." mode="addErrorCodeRef">
				<xsl:with-param name="errorCode">412</xsl:with-param>
			</xsl:apply-templates>
		</xsl:if>
		
		<xsl:if test="xfn:includeProperty('413', $inlcudeErrorCodes, $excludeErrorCodes)">
			<xsl:apply-templates select="." mode="addErrorCodeRef">
				<xsl:with-param name="errorCode">413</xsl:with-param>
			</xsl:apply-templates>
		</xsl:if>
		
		<xsl:if test="xfn:includeProperty('415', $inlcudeErrorCodes, $excludeErrorCodes)">
			<xsl:apply-templates select="." mode="addErrorCodeRef">
				<xsl:with-param name="errorCode">415</xsl:with-param>
			</xsl:apply-templates>
		</xsl:if>
		
		<xsl:if test="xfn:includeProperty('500', $inlcudeErrorCodes, $excludeErrorCodes)">
			<xsl:apply-templates select="." mode="addErrorCodeRef">
				<xsl:with-param name="errorCode">500</xsl:with-param>
			</xsl:apply-templates>
		</xsl:if>
		
		<xsl:if test="xfn:includeProperty('501', $inlcudeErrorCodes, $excludeErrorCodes)">
			<xsl:apply-templates select="." mode="addErrorCodeRef">
				<xsl:with-param name="errorCode">501</xsl:with-param>
			</xsl:apply-templates>
		</xsl:if>
		
		<xsl:if test="xfn:includeProperty('503', $inlcudeErrorCodes, $excludeErrorCodes)">
			<xsl:apply-templates select="." mode="addErrorCodeRef">
				<xsl:with-param name="errorCode">503</xsl:with-param>
			</xsl:apply-templates>
		</xsl:if>
    </xsl:template>

    <!-- ===================================================== -->
    <!-- Template: Listing all possible HTTP  Request Headers. -->
    <!-- ===================================================== -->
    <xsl:template match="specgen:DataObject" mode="addRequestHTTPHeaderList">
		<xsl:param name="excludeHTTPHeaders"/>
		<xsl:if test="not(contains($excludeHTTPHeaders, 'authorization'))">
			<xsl:apply-templates select="." mode="addRequestHTTPHeaderRef">
				<xsl:with-param name="hdrName">authorization</xsl:with-param>
			</xsl:apply-templates>
		</xsl:if>
		
		<xsl:if test="$produceAllHeaders">
			<xsl:if test="not(contains($excludeHTTPHeaders, 'accept'))">
				<xsl:apply-templates select="." mode="addRequestHTTPHeaderRef">
					<xsl:with-param name="hdrName">accept</xsl:with-param>
				</xsl:apply-templates>
			</xsl:if>
			
			<xsl:if test="not(contains($excludeHTTPHeaders, 'accept-encoding'))">
				<xsl:apply-templates select="." mode="addRequestHTTPHeaderRef">
					<xsl:with-param name="hdrName">accept-encoding</xsl:with-param>
				</xsl:apply-templates>
			</xsl:if>
	
			<xsl:if test="not(contains($excludeHTTPHeaders, 'accept-profile'))">
				<xsl:apply-templates select="." mode="addRequestHTTPHeaderRef">
					<xsl:with-param name="hdrName">accept-profile</xsl:with-param>
				</xsl:apply-templates>
			</xsl:if>
	
			<xsl:if test="not(contains($excludeHTTPHeaders, 'applicationKey'))">
				<xsl:apply-templates select="." mode="addRequestHTTPHeaderRef">
					<xsl:with-param name="hdrName">applicationKey</xsl:with-param>
				</xsl:apply-templates>
			</xsl:if>
	
			<xsl:if test="not(contains($excludeHTTPHeaders, 'authenticatedUser'))">
				<xsl:apply-templates select="." mode="addRequestHTTPHeaderRef">
					<xsl:with-param name="hdrName">authenticatedUser</xsl:with-param>
				</xsl:apply-templates>
			</xsl:if>
	
			<xsl:if test="not(contains($excludeHTTPHeaders, 'connectionId'))">
				<xsl:apply-templates select="." mode="addRequestHTTPHeaderRef">
					<xsl:with-param name="hdrName">connectionId</xsl:with-param>
				</xsl:apply-templates>
			</xsl:if>

			<xsl:if test="not(contains($excludeHTTPHeaders, 'content-type'))">
				<xsl:apply-templates select="." mode="addRequestHTTPHeaderRef">
					<xsl:with-param name="hdrName">content-type</xsl:with-param>
				</xsl:apply-templates>
			</xsl:if>
	
			<xsl:if test="not(contains($excludeHTTPHeaders, 'content-encoding'))">
				<xsl:apply-templates select="." mode="addRequestHTTPHeaderRef">
					<xsl:with-param name="hdrName">content-encoding</xsl:with-param>
				</xsl:apply-templates>
			</xsl:if>
	
			<xsl:if test="not(contains($excludeHTTPHeaders, 'content-profile'))">
				<xsl:apply-templates select="." mode="addRequestHTTPHeaderRef">
					<xsl:with-param name="hdrName">content-profile</xsl:with-param>
				</xsl:apply-templates>
			</xsl:if>
	
			<xsl:if test="not(contains($excludeHTTPHeaders, 'dataPrivacyMarkerStd'))">
				<xsl:apply-templates select="." mode="addRequestHTTPHeaderRef">
					<xsl:with-param name="hdrName">dataPrivacyMarkerStd</xsl:with-param>
				</xsl:apply-templates>
			</xsl:if>
	
			<xsl:if test="not(contains($excludeHTTPHeaders, 'dataPrivacyMarkerBatchPutRequest'))">
				<xsl:apply-templates select="." mode="addRequestHTTPHeaderRef">
					<xsl:with-param name="hdrName">dataPrivacyMarkerBatchPutRequest</xsl:with-param>
				</xsl:apply-templates>
			</xsl:if>
<!-- 
			<xsl:if test="not(contains($excludeHTTPHeaders, 'ETag'))">
				<xsl:apply-templates select="." mode="addRequestHTTPHeaderRef">
					<xsl:with-param name="hdrName">ETag</xsl:with-param>
				</xsl:apply-templates>
			</xsl:if>
-->	
			<xsl:if test="not(contains($excludeHTTPHeaders, 'fingerprint'))">
				<xsl:apply-templates select="." mode="addRequestHTTPHeaderRef">
					<xsl:with-param name="hdrName">fingerprint</xsl:with-param>
				</xsl:apply-templates>
			</xsl:if>
			<xsl:if test="not(contains($excludeHTTPHeaders, 'generatorId'))">
				<xsl:apply-templates select="." mode="addRequestHTTPHeaderRef">
					<xsl:with-param name="hdrName">generatorId</xsl:with-param>
				</xsl:apply-templates>
			</xsl:if>
		</xsl:if>
		
		<xsl:if test="not(contains($excludeHTTPHeaders, 'messageId'))">
			<xsl:apply-templates select="." mode="addRequestHTTPHeaderRef">
				<xsl:with-param name="hdrName">messageId</xsl:with-param>
			</xsl:apply-templates>
		</xsl:if>

		<xsl:if test="$produceAllHeaders">
			<xsl:if test="not(contains($excludeHTTPHeaders, 'messageType'))">
				<xsl:apply-templates select="." mode="addRequestHTTPHeaderRef">
					<xsl:with-param name="hdrName">messageType</xsl:with-param>
				</xsl:apply-templates>
			</xsl:if>
		</xsl:if>
		
		<xsl:if test="not(contains($excludeHTTPHeaders, 'methodOverridePut'))">
			<xsl:apply-templates select="." mode="addRequestHTTPHeaderRef">
				<xsl:with-param name="hdrName">methodOverridePut</xsl:with-param>
			</xsl:apply-templates>
		</xsl:if>

		<xsl:if test="not(contains($excludeHTTPHeaders, 'methodOverridePost'))">
			<xsl:apply-templates select="." mode="addRequestHTTPHeaderRef">
				<xsl:with-param name="hdrName">methodOverridePost</xsl:with-param>
			</xsl:apply-templates>
		</xsl:if>

		<xsl:if test="not(contains($excludeHTTPHeaders, 'mustUseAdvisory'))">
			<xsl:apply-templates select="." mode="addRequestHTTPHeaderRef">
				<xsl:with-param name="hdrName">mustUseAdvisory</xsl:with-param>
			</xsl:apply-templates>
		</xsl:if>

		<xsl:if test="$produceAllHeaders">
			<xsl:if test="not(contains($excludeHTTPHeaders, 'navigationId'))">
				<xsl:apply-templates select="." mode="addRequestHTTPHeaderRef">
					<xsl:with-param name="hdrName">navigationId</xsl:with-param>
				</xsl:apply-templates>
			</xsl:if>
		</xsl:if>

		<xsl:if test="not(contains($excludeHTTPHeaders, 'navigationPage'))">
			<xsl:apply-templates select="." mode="addRequestHTTPHeaderRef">
				<xsl:with-param name="hdrName">navigationPage</xsl:with-param>
			</xsl:apply-templates>
		</xsl:if>

		<xsl:if test="not(contains($excludeHTTPHeaders, 'navigationPageSize'))">
			<xsl:apply-templates select="." mode="addRequestHTTPHeaderRef">
				<xsl:with-param name="hdrName">navigationPageSize</xsl:with-param>
			</xsl:apply-templates>
		</xsl:if>

		<xsl:if test="not(contains($excludeHTTPHeaders, 'queryIntention'))">
			<xsl:apply-templates select="." mode="addRequestHTTPHeaderRef">
				<xsl:with-param name="hdrName">queryIntention</xsl:with-param>
			</xsl:apply-templates>
		</xsl:if>

		<xsl:if test="$produceAllHeaders">
			<xsl:if test="not(contains($excludeHTTPHeaders, 'queueId'))">
				<xsl:apply-templates select="." mode="addRequestHTTPHeaderRef">
					<xsl:with-param name="hdrName">queueId</xsl:with-param>
				</xsl:apply-templates>
			</xsl:if>
		</xsl:if>

		<xsl:if test="not(contains($excludeHTTPHeaders, 'replacement'))">
			<xsl:apply-templates select="." mode="addRequestHTTPHeaderRef">
				<xsl:with-param name="hdrName">replacement</xsl:with-param>
			</xsl:apply-templates>
		</xsl:if>

		<xsl:if test="not(contains($excludeHTTPHeaders, 'requestId'))">
			<xsl:apply-templates select="." mode="addRequestHTTPHeaderRef">
				<xsl:with-param name="hdrName">requestId</xsl:with-param>
			</xsl:apply-templates>
		</xsl:if>

		<xsl:if test="$produceAllHeaders">
			<xsl:if test="not(contains($excludeHTTPHeaders, 'requestAction'))">
				<xsl:apply-templates select="." mode="addRequestHTTPHeaderRef">
					<xsl:with-param name="hdrName">requestAction</xsl:with-param>
				</xsl:apply-templates>
			</xsl:if>
		</xsl:if>
		
		<xsl:if test="not(contains($excludeHTTPHeaders, 'requestType'))">
			<xsl:apply-templates select="." mode="addRequestHTTPHeaderRef">
				<xsl:with-param name="hdrName">requestType</xsl:with-param>
			</xsl:apply-templates>
		</xsl:if>

		<xsl:if test="$produceAllHeaders">
			<xsl:if test="not(contains($excludeHTTPHeaders, 'serviceType'))">
				<xsl:apply-templates select="." mode="addRequestHTTPHeaderRef">
					<xsl:with-param name="hdrName">serviceType</xsl:with-param>
				</xsl:apply-templates>
			</xsl:if>

			<xsl:if test="not(contains($excludeHTTPHeaders, 'serviceSubType'))">
				<xsl:apply-templates select="." mode="addRequestHTTPHeaderRef">
					<xsl:with-param name="hdrName">serviceSubType</xsl:with-param>
				</xsl:apply-templates>
			</xsl:if>

			<xsl:if test="not(contains($excludeHTTPHeaders, 'sourceName'))">
				<xsl:apply-templates select="." mode="addRequestHTTPHeaderRef">
					<xsl:with-param name="hdrName">sourceName</xsl:with-param>
				</xsl:apply-templates>
			</xsl:if>
		</xsl:if>
		
		<xsl:if test="not(contains($excludeHTTPHeaders, 'timestamp'))">
			<xsl:apply-templates select="." mode="addRequestHTTPHeaderRef">
				<xsl:with-param name="hdrName">timestamp</xsl:with-param>
			</xsl:apply-templates>
		</xsl:if>

    </xsl:template>
    
    <!-- =================================================== -->
    <!-- Template: Listing all possible URL Query Paramters. -->
    <!-- =================================================== -->
    <xsl:template match="specgen:DataObject" mode="addQueryParamterList">
		<xsl:param name="excludeQueryParamters"/>
		<xsl:if test="not(contains($excludeQueryParamters, 'changesSinceMarker'))">
			<xsl:apply-templates select="." mode="addQueryParameterRef">
				<xsl:with-param name="paramName">changesSinceMarker</xsl:with-param>
			</xsl:apply-templates>
		</xsl:if>
		
		<xsl:if test="not(contains($excludeQueryParamters, 'order'))">
			<xsl:apply-templates select="." mode="addQueryParameterRef">
				<xsl:with-param name="paramName">order</xsl:with-param>
			</xsl:apply-templates>
		</xsl:if>
		
		<xsl:if test="not(contains($excludeQueryParamters, 'where'))">
			<xsl:apply-templates select="." mode="addQueryParameterRef">
				<xsl:with-param name="paramName">where</xsl:with-param>
			</xsl:apply-templates>
		</xsl:if>
	</xsl:template>

    <!-- ================================================ -->
    <!-- Template for producing request HTTP Headers Refs -->
    <!-- ================================================= -->
	<xsl:template match="specgen:DataObject" mode="addRequestHTTPHeaderRef">
		<xsl:param name="hdrName"/>
		<xsl:value-of select="concat('      - $ref: ', '''', $commonDefsFileName,'#/components/schemas/httpHeaders/request/', $hdrName,'''', '&#x0a;')"/>
	</xsl:template>

    <!-- ================================================== -->
    <!-- Template for producing request URL Query Parameter -->
    <!-- ================================================== -->
	<xsl:template match="specgen:DataObject" mode="addQueryParameterRef">
		<xsl:param name="paramName"/>
		<xsl:value-of select="concat('      - $ref: ', '''', $commonDefsFileName,'#/components/schemas/queryParameters/', $paramName,'''', '&#x0a;')"/>
	</xsl:template>

    <!-- ======================================= -->
    <!-- Template for producing Error Codes Refs -->
    <!-- ======================================= -->
	<xsl:template match="specgen:DataObject" mode="addErrorCodeRef">
		<xsl:param name="errorCode"/>
		<xsl:value-of select="concat('        ''', $errorCode,'''', ':&#x0a;')"/>
		<xsl:value-of select="concat('          $ref: ', '''', $commonDefsFileName,'#/components/schemas/errorResponses/responses/', $errorCode,'''', '&#x0a;')"/>
	</xsl:template>

	<!-- Bring Description, Intro or Text mixed content elements across with all its embedded html -->
	<xsl:template match="specgen:Description|specgen:Intro|specgen:Text">
		<xsl:variable name="descr"><xsl:apply-templates/></xsl:variable>

		<xsl:value-of select="normalize-space(translate($descr, ':', ''))"/>
	</xsl:template>
	
	<xsl:template match="specgen:p|specgen:br|specgen:a
						 |specgen:code|specgen:strong|specgen:em|specgen:span
						 |specgen:h1|specgen:h2|specgen:h3|specgen:h4
						 |specgen:ul|specgen:ol|specgen:li
						 |specgen:dl|specgen:dt|specgen:dd
						 |specgen:table|specgen:thead|specgen:tbody|specgen:tr|specgen:th|specgen:td">
		<xsl:value-of select="concat('&lt;', local-name(.))"/>
		<xsl:for-each select="@*">
			<xsl:value-of select="concat(' ', local-name(.), '=&quot;', . , '&quot;')"/>
		</xsl:for-each>
		<xsl:choose>
			<xsl:when test="not(*) and not(normalize-space())">
				<xsl:text>/&gt;</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>&gt;</xsl:text>
				<xsl:apply-templates/>
				<xsl:value-of select="concat('&lt;/', local-name(.), '&gt;')"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

    <xsl:template match="node/@TEXT | text()" name="removeBreaks">
        <xsl:param name="pText" select="normalize-space(.)"/>
        <xsl:choose>
            <xsl:when test="not(contains($pText, '&#xA;'))"><xsl:copy-of select="$pText"/></xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat(substring-before($pText, '&#xD;&#xA;'), ' ')"/>
                <xsl:call-template name="removeBreaks">
                    <xsl:with-param name="pText" select="substring-after($pText, '&#xD;&#xA;')"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

	<!-- Custom function to chop 'Type' off the end of XSD type names -->
	<xsl:function name="xfn:chopType" as="xs:string">
		<xsl:param name="inp"/>
		<xsl:choose>
			<xsl:when test="ends-with($inp, 'Type')">
				<xsl:value-of select="substring($inp, 1, string-length($inp)-4)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$inp"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<!-- Custom function to tidy up URL -->
	<xsl:function name="xfn:cleanUrl" as="xs:string">
		<xsl:param name="inUrl"/>
		<xsl:value-of select="replace(replace($inUrl, ' ', ''), '&amp;', '')"/>
	</xsl:function>

	<xsl:variable name="q">
		<xsl:text>"</xsl:text>
	</xsl:variable>
	<xsl:variable name="empty"/>

	<xsl:function name="xfn:includeProperty" as="xs:boolean">
		<xsl:param name="value" as="xs:string" />
		<xsl:param name="includeList" as="xs:string" />
		<xsl:param name="excludeList" as="xs:string" />
	    <xsl:sequence select="contains($includeList, $value) and not(contains($excludeList, $value))" />
	</xsl:function>

	<!-- returns true if value is not set or empty -->
	<xsl:function name="xfn:empty" as="xs:boolean">
		<xsl:param name="value"/>
		<xsl:sequence select="not($value != '')" />
	</xsl:function>

	<!-- returns true if value is not set or empty or has the value of 'true' -->
	<xsl:function name="xfn:emptyOrTrue" as="xs:boolean">
		<xsl:param name="value"/>
		<xsl:sequence select="xfn:empty($value) or $value = true()" />
	</xsl:function>
	
	<!-- returns true if listOfValues is empty or if the valueToCheck is in the given comma separated listOfValues -->
	<xsl:function name="xfn:containsOrEmpty" as="xs:boolean">
		<xsl:param name="listOfValues"/>
		<xsl:param name="valueToCheck"/>
		<xsl:sequence select="xfn:empty($listOfValues) or contains($listOfValues, $valueToCheck)" />
	</xsl:function>
	
	<!-- 
		If the condition is true it will return the concatination of the baseString and the stringToAdd.
	    If the condition is not met then only the baseString is returned.
	-->
	<xsl:function name="xfn:conditinalConcat" as="xs:string">
		<xsl:param name="condition" as="xs:boolean"/>
		<xsl:param name="baseString"/>
		<xsl:param name="stringToAdd"/>
		
		<xsl:choose>
			<xsl:when test="$condition">
				<xsl:value-of select="concat($baseString, $stringToAdd)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$baseString"/>
			</xsl:otherwise>
		</xsl:choose>
              </xsl:function>

        <!-- NN 20221216 deal with recursively defined IdRef and RefId, which JSON Reference does not tolerate -->
        <xsl:function name="xfn:refresolve" as="xs:string">
          <xsl:param name="value"/>
          <xsl:choose>
            <xsl:when test="$value eq 'IdRef'">GUID</xsl:when>
            <xsl:when test="$value eq 'RefId'">GUID</xsl:when>
            <xsl:when test="$value eq 'LearningResourcePackage'">AbstractContentElement</xsl:when>
            <xsl:otherwise><xsl:value-of select="$value"/></xsl:otherwise>
          </xsl:choose>
        </xsl:function>

	
</xsl:stylesheet>
