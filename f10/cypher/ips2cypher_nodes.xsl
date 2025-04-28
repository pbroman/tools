<?xml version="1.0"?>
<xsl:stylesheet version="1.1" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:variable name="apos">'</xsl:variable>
    <xsl:variable name="quot">"</xsl:variable>

    <xsl:output method="text"/>

    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="dir">
        <xsl:for-each select="PolicyCmptType | ProductCmptType2 | EnumType | EnumContent ">
            <xsl:variable name="className" select="@className"/>
            <xsl:variable name="classType" select="name(.)"/>

            <xsl:if test="$className">
                <!-- Node -->
                <xsl:value-of select="concat('CREATE (', $className, ':', $classType, ' {name:', $quot, $className, $quot, ', attributes:[')"/>
                <xsl:for-each select="Attribute">
                    <xsl:value-of select="concat($apos, @name, $apos)"/>
                    <xsl:if test="position() != last()">
                        <xsl:text>,</xsl:text>
                    </xsl:if>
                </xsl:for-each>
                <xsl:text>]})&#xa;</xsl:text>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

</xsl:stylesheet>