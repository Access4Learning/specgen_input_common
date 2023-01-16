<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:specgen="http://sifassociation.org/SpecGen"
	xmlns:xfn="http://stuart.geek.nz/xslt-functions"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:xml="http://www.w3.org/XML/1998/namespace">

	<xsl:output method="text" omit-xml-declaration="yes" indent="no"/>

        <xsl:param name="sifVersion"/>
        <xsl:param name="sifLocale"/>
        <xsl:param name="sifObjectList" select="''"/> <!-- Default to empty list -->
        <xsl:param name="sifObjectGroupList" select="''"/> <!-- Default to empty list -->
        <xsl:param name="includeAllHeaders" select="'false'" as="xs:string"/> <!-- If false we only show minimum number of headers -->
        <xsl:param name="includeAdminDirectives" select="'false'" as="xs:string"/> <!-- If true admin directives endpoints will be included. -->
        <xsl:param name="omitVersionInExamplesFileName" select="'false'" as="xs:string"/> <!-- If true admin directives endpoints will be included. -->

        <!-- NN 20230116 Whether we are compliant with OpenAPI 3.0 JSON Schema (true), or full JSON Schema, i.e. OpenAPI 3.1 (false). -->
	<xsl:param name="openAPI30">false</xsl:param>
	
    <!-- Now that we've configured all the options -->
    <xsl:include href="dmToOpenAPI.xsl"/>
</xsl:stylesheet>
