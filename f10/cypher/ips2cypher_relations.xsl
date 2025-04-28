<?xml version="1.0"?>
<xsl:stylesheet version="1.1" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:variable name="apos">'</xsl:variable>
    <xsl:variable name="quot">"</xsl:variable>

    <xsl:output method="text"/>

    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="dir">
        <xsl:for-each select="PolicyCmptType | ProductCmptType2">
            <xsl:variable name="className" select="@className"/>

            <xsl:if test="$className">

                <!-- Inheritance relation -->
                <xsl:if test="@supertype">
                    <xsl:value-of select="concat('CREATE (', $className, ')-[:EXTENDS]->(', @supertype, ')&#xa;')"/>
                </xsl:if>

                <!-- Product type relation -->
<!--
                <xsl:if test="@productCmptType">
                    <xsl:value-of select="concat('CREATE (', $className, ')-[:USES]->(', @productCmptType, ')&#xa;')"/>
                </xsl:if>
-->
                <!-- Policy type relation -->
                <xsl:if test="@policyCmptType">
                    <xsl:value-of select="concat('CREATE (', $className, ')-[:USED_BY]->(', @policyCmptType, ')&#xa;')"/>
                </xsl:if>

                <!-- Compositions (only found in policy types) -->
                <xsl:for-each select="Association[@associationType='comp']">
                    <xsl:variable name="target">
                        <xsl:value-of select="@target"/>
                    </xsl:variable>
                    <xsl:variable name="targetMin">
                        <xsl:value-of
                                select="../../PolicyCmptType[@className=$target]/Association[@associationType='reverseComp' and @target=$className]/@minCardinality"/>
                    </xsl:variable>
                    <xsl:variable name="targetMax">
                        <xsl:value-of
                                select="../../PolicyCmptType[@className=$target]/Association[@associationType='reverseComp' and @target=$className]/@maxCardinality"/>
                    </xsl:variable>

                    <xsl:value-of select="concat('CREATE (', $className, ')-[:', @targetRoleSingular, ' {type: ', $quot, 'composition', $quot)"/>
                    <xsl:value-of select="concat(', card: ', $quot, @minCardinality, '..', @maxCardinality, $quot)"/>
                    <xsl:if test="$targetMin != '' and $targetMax != ''">
                        <xsl:value-of select="concat(', targetCard: ', $quot, $targetMin, '..', $targetMax, $quot)"/>
                    </xsl:if>
                    <xsl:value-of select="concat('}]->(', $target, ')&#xa;')"/>
                </xsl:for-each>

                <!-- Aggregations (only found in product types) -->
                <xsl:for-each select="Association[@associationType='aggr']">
                    <xsl:variable name="target">
                        <xsl:value-of select="@target"/>
                    </xsl:variable>
                    <xsl:value-of select="concat('CREATE (', $className, ')-[:', @targetRoleSingular, ' {type: ', $quot, 'aggregation', $quot)"/>
                    <xsl:value-of select="concat(', card: ', $quot, @minCardinality, '..', @maxCardinality, $quot)"/>
                    <xsl:value-of select="concat('}]->(', $target, ')&#xa;')"/>
                </xsl:for-each>

                <!-- Associations -->
                <xsl:for-each select="Association[@associationType='ass']">
                    <xsl:value-of select="concat('CREATE (', $className, ')-[:', @targetRoleSingular, ' {type: ', $quot, 'association', $quot, '}]->(', @target, ')&#xa;')"/>
                </xsl:for-each>
            </xsl:if>
        </xsl:for-each>

        <xsl:for-each select="EnumContent">
            <xsl:value-of select="concat('CREATE (', @className, ')-[:DEFINES]->(', @enumType, 'Type)&#xa;')"/>
        </xsl:for-each>

        <xsl:for-each select="EnumType">
            <xsl:if test="@superEnumType"> <!--  and @superEnumType != 'AbstractLocalizedBaseEnum' -->
                <xsl:value-of select="concat('CREATE (', @className, ')-[:EXTENDS]->(', @superEnumType, 'Type)&#xa;')"/>
            </xsl:if>
        </xsl:for-each>

    </xsl:template>

</xsl:stylesheet>