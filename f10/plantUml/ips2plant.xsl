<?xml version="1.0"?>
<xsl:stylesheet version="1.1" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:param name="printTargetRole"/>
    <xsl:param name="addSuperType"/>
    <xsl:param name="addPolicyCmptType"/>
    <xsl:param name="addProductCmptType"/>
    <xsl:param name="groupClasses"/>

    <xsl:variable name="policySpot">(V,lightSteelBlue)</xsl:variable>
    <xsl:variable name="productSpot">(P,deepSkyBlue)</xsl:variable>
    <xsl:variable name="policyType">PolicyCmptType</xsl:variable>
    <xsl:variable name="productType">ProductCmptType</xsl:variable>
    <xsl:variable name="ff">&gt;&gt;</xsl:variable>
    <xsl:variable name="bb">&lt;&lt;</xsl:variable>

    <xsl:output method="text"/>

    <xsl:template match="/">
        <xsl:text>@startuml&#xa;</xsl:text>
        <xsl:text>hide empty members&#xa;</xsl:text>

        <xsl:apply-templates/>

        <xsl:text>@enduml&#xa;</xsl:text>
    </xsl:template>

    <xsl:template match="dir">
        <xsl:if test="$groupClasses = 'true'">
            <xsl:value-of select="concat('package ', @name, ' { &#xa;')"/>
        </xsl:if>

        <xsl:for-each select="PolicyCmptType | ProductCmptType2">
            <xsl:variable name="className">
                <xsl:value-of select="@className"/>
            </xsl:variable>

            <xsl:variable name="spot">
                <xsl:choose>
                    <xsl:when test="name(.) = 'ProductCmptType2' and not(@abstract)">(P,deepSkyBlue)</xsl:when>
                    <xsl:when test="name(.) = 'PolicyCmptType' and not(@abstract)">(V,lightSteelBlue)</xsl:when>
                    <xsl:otherwise/>
                </xsl:choose>
            </xsl:variable>

            <xsl:variable name="classType">
                <xsl:choose>
                    <xsl:when test="name(.) = 'ProductCmptType2'">
                        <xsl:value-of select="concat($bb, $spot, $productType, $ff)"/>
                    </xsl:when>
                    <xsl:when test="name(.) = 'PolicyCmptType'">
                        <xsl:value-of select="concat($bb, $spot, $policyType, $ff)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="concat($bb, name(.), $ff)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>

            <!-- Class -->
            <xsl:if test="@abstract='true'">
                <xsl:text>abstract </xsl:text>
            </xsl:if>
            <xsl:value-of select="concat('class ', $className, $classType, ' { &#xa;')"/>
            <xsl:for-each select="Attribute">
                <xsl:sort select="@name"/>
                <xsl:variable name="attrType">
                    <xsl:choose>
                        <xsl:when test="@attributeType='changeable'">+</xsl:when>
                        <xsl:when test="@attributeType='derived'">~</xsl:when>
                        <xsl:when test="@attributeType='computed'">#</xsl:when>
                        <xsl:when test="@attributeType='constant'">-</xsl:when>
                    </xsl:choose>
                </xsl:variable>
                <xsl:value-of select="concat('  ', $attrType, @name, ': ', @datatype, '&#xa;')"/>
            </xsl:for-each>
            <xsl:text>}&#xa;</xsl:text>

            <!-- Inheritance -->
            <xsl:variable name="superType">
                <xsl:value-of select="@supertype"/>
            </xsl:variable>
            <xsl:if test="@supertype and $addSuperType = 'true'">
                <xsl:value-of select="concat('class ', $superType, $bb, $policySpot, $policyType, $ff, ' {} &#xa;')"/>
                <xsl:value-of select="concat($superType, ' &lt;|-- ', $className, '&#xa;')"/>
            </xsl:if>

            <!-- Product type relation -->
            <xsl:variable name="productCmptType">
                <xsl:value-of select="@productCmptType"/>
            </xsl:variable>
            <xsl:if test="@productCmptType and $addProductCmptType = 'true'">
                <xsl:value-of
                        select="concat('class ', $productCmptType, $bb, $productSpot, $productType, $ff, ' {} &#xa;')"/>
                <xsl:value-of select="concat($className, ' --# ', $productCmptType, '&#xa;')"/>
            </xsl:if>

            <!-- Policy type relation -->
            <xsl:variable name="policyCmptType">
                <xsl:value-of select="concat('policy.', @policyCmptType)"/>
            </xsl:variable>
            <xsl:if test="@policyCmptType and $addPolicyCmptType = 'true'">
                <xsl:value-of select="concat($className, ' --# ', $policyCmptType, '&#xa;')"/>
            </xsl:if>

            <!-- Compositions -->
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

                <xsl:value-of select="$className"/>
                <xsl:if test="$targetMin != '' and $targetMax != ''">
                    <xsl:value-of select="concat(' &quot;', $targetMin, '..', $targetMax, '&quot; ')"/>
                </xsl:if>
                <xsl:value-of
                        select="concat(' *-- &quot;', @minCardinality, '..', @maxCardinality, '&quot; ', $target)"/>
                <xsl:if test="@targetRoleSingular and $printTargetRole = 'true'">
                    <xsl:value-of select="concat(' : ', @targetRoleSingular)"/>
                </xsl:if>
                <xsl:text>&#xa;</xsl:text>
            </xsl:for-each>

            <!-- Aggregations -->
            <xsl:for-each select="Association[@associationType='aggr']">
                <xsl:variable name="target">
                    <xsl:value-of select="@target"/>
                </xsl:variable>
                <xsl:value-of
                        select="concat($className, ' o-- &quot;', @minCardinality, '..', @maxCardinality, '&quot; ', $target)"/>
                <xsl:if test="@targetRoleSingular and $printTargetRole = 'true'">
                    <xsl:value-of select="concat(' : ', @targetRoleSingular)"/>
                </xsl:if>
                <xsl:text>&#xa;</xsl:text>
            </xsl:for-each>

            <!-- Associations -->
            <xsl:for-each select="Association[@associationType='ass']">
                <xsl:value-of select="concat(@target, ' .. ', $className, '&#xa;')"/>
            </xsl:for-each>
        </xsl:for-each>

        <xsl:if test="$groupClasses = 'true'">
            <xsl:text>} &#xa;</xsl:text>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>