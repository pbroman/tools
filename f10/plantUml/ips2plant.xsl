<?xml version="1.0"?>
<xsl:stylesheet version="1.1" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:param name="printTargetRole"/>
    <xsl:param name="addSuperType"/>
    <xsl:param name="addPolicyCmptType"/>
    <xsl:param name="addProductCmptType"/>
    <xsl:param name="packages"/>
    <xsl:param name="connector"/>
    <xsl:param name="args"/>

    <xsl:variable name="policySpot">(V,lightSteelBlue)</xsl:variable>
    <xsl:variable name="productSpot">(P,deepSkyBlue)</xsl:variable>
    <xsl:variable name="policyType">PolicyCmptType</xsl:variable>
    <xsl:variable name="productType">ProductCmptType</xsl:variable>
    <xsl:variable name="ff">&gt;&gt;</xsl:variable>
    <xsl:variable name="bb">&lt;&lt;</xsl:variable>
    <xsl:variable name="singleQuote">'</xsl:variable>

    <xsl:output method="text"/>

    <xsl:template match="/">
        <xsl:text>@startuml&#xa;</xsl:text>
        <xsl:value-of select="concat($singleQuote, 'This diagram was created with args ', $args, $singleQuote, '&#xa;&#xa;' )"/>
        <xsl:text>hide empty members&#xa;</xsl:text>

        <xsl:apply-templates/>

        <xsl:text>@enduml&#xa;</xsl:text>
    </xsl:template>

    <xsl:template match="PolicyCmptType">
        <xsl:variable name="classNameWithPackage">
            <xsl:value-of select="@className"/>
        </xsl:variable>

        <xsl:variable name="className">
            <xsl:call-template name="packaging-selector">
                <xsl:with-param name="clazz" select="@className" />
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="spot">
            <xsl:choose>
                <xsl:when test="name(.) = 'ProductCmptType2' and not(@abstract)"><xsl:value-of select="$productSpot"/></xsl:when>
                <xsl:when test="name(.) = 'PolicyCmptType' and not(@abstract)"><xsl:value-of select="$policySpot"/></xsl:when>
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
        <xsl:if test="@supertype and $addSuperType = 'true'">
            <xsl:variable name="superType">
                <xsl:call-template name="packaging-selector">
                    <xsl:with-param name="clazz" select="@supertype" />
                </xsl:call-template>
            </xsl:variable>
            <xsl:value-of select="concat('class ', $superType, $bb, $policySpot, $policyType, $ff, ' {} &#xa;')"/>
            <xsl:value-of select="concat($superType, ' &lt;|', $connector, ' ', $className, '&#xa;')"/>
        </xsl:if>

        <!-- Product type relation -->
        <xsl:variable name="productCmptType">
            <xsl:value-of select="@productCmptType"/>
        </xsl:variable>
        <xsl:if test="@productCmptType and $addProductCmptType = 'true'">
            <xsl:value-of
                    select="concat('class ', $productCmptType, $bb, $productSpot, $productType, $ff, ' {} &#xa;')"/>
            <xsl:value-of select="concat($className, ' ', $connector, '# ', $productCmptType, '&#xa;')"/>
        </xsl:if>

        <!-- Policy type relation -->
        <xsl:variable name="policyCmptType">
            <xsl:value-of select="concat('policy.', @policyCmptType)"/>
        </xsl:variable>
        <xsl:if test="@policyCmptType and $addPolicyCmptType = 'true'">
            <xsl:value-of select="concat($className, ' ', $connector, '# ', $policyCmptType, '&#xa;')"/>
        </xsl:if>

        <!-- Compositions -->
        <xsl:for-each select="Association[@associationType='comp']">
            <xsl:variable name="targetWithPackage">
                <xsl:value-of select="@target"/>
            </xsl:variable>
            <xsl:variable name="target">
                <xsl:call-template name="packaging-selector">
                    <xsl:with-param name="clazz" select="@target" />
                </xsl:call-template>
            </xsl:variable>

            <xsl:variable name="targetMin">
                <xsl:value-of
                        select="../../PolicyCmptType[@className=$targetWithPackage]/Association[@associationType='reverseComp' and @target=$classNameWithPackage]/@minCardinality"/>
            </xsl:variable>
            <xsl:variable name="targetMax">
                <xsl:value-of
                        select="../../PolicyCmptType[@className=$targetWithPackage]/Association[@associationType='reverseComp' and @target=$classNameWithPackage]/@maxCardinality"/>
            </xsl:variable>

            <xsl:value-of select="$className"/>
            <xsl:if test="$targetMin != '' and $targetMax != ''">
                <xsl:value-of select="concat(' &quot;', $targetMin, '..', $targetMax, '&quot; ')"/>
            </xsl:if>
            <xsl:value-of
                    select="concat(' *', $connector, ' &quot;', @minCardinality, '..', @maxCardinality, '&quot; ', $target)"/>
            <xsl:if test="@targetRoleSingular and $printTargetRole = 'true'">
                <xsl:value-of select="concat(' : ', @targetRoleSingular)"/>
            </xsl:if>
            <xsl:text>&#xa;</xsl:text>
        </xsl:for-each>

        <!-- Associations -->
        <xsl:for-each select="Association[@associationType='ass']">
            <xsl:variable name="target">
                <xsl:call-template name="packaging-selector">
                    <xsl:with-param name="clazz" select="@target" />
                </xsl:call-template>
            </xsl:variable>

            <xsl:value-of select="concat($target, ' .. ', $className)"/>
            <xsl:if test="@targetRoleSingular and $printTargetRole = 'true'">
                <xsl:value-of select="concat(' : ', @targetRoleSingular)"/>
            </xsl:if>
            <xsl:text>&#xa;</xsl:text>
        </xsl:for-each>

        <!-- Aggregations -->
        <xsl:for-each select="Association[@associationType='aggr']">
            <xsl:variable name="target">
                <xsl:call-template name="packaging-selector">
                    <xsl:with-param name="clazz" select="@target" />
                </xsl:call-template>
            </xsl:variable>

            <xsl:value-of
                    select="concat($className, ' o', $connector, ' &quot;', @minCardinality, '..', @maxCardinality, '&quot; ', $target)"/>
            <xsl:if test="@targetRoleSingular and $printTargetRole = 'true'">
                <xsl:value-of select="concat(' : ', @targetRoleSingular)"/>
            </xsl:if>
            <xsl:text>&#xa;</xsl:text>
        </xsl:for-each>

    </xsl:template>

    <xsl:template name="substring-after-last">
        <xsl:param name="string" />
        <xsl:param name="delimiter" />
        <xsl:choose>
            <xsl:when test="contains($string, $delimiter)">
                <xsl:call-template name="substring-after-last">
                    <xsl:with-param name="string" select="substring-after($string, $delimiter)" />
                    <xsl:with-param name="delimiter" select="$delimiter" />
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise><xsl:value-of select="$string" /></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="packaging-selector">
        <xsl:param name="clazz"/>
        <xsl:choose>
            <xsl:when test="$packages">
                <xsl:value-of select="$clazz"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="substring-after-last">
                    <xsl:with-param name="string" select="$clazz" />
                    <xsl:with-param name="delimiter" select="'.'" />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>