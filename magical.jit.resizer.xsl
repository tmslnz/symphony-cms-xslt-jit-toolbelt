<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:exsl="http://exslt.org/common" extension-element-prefixes="exsl">
    <!-- 
        ////////////////////////////    Magical Image Resize Utility
        //    ///////////////    ///    ============================
        ///    /////////////    ////    
        ////    ///// /////    /////    
        /////    ///   ///    //////    
        //////    /     /    ///////    
        ///////             ////////    
        ////////    //     /////////    
        /////////  ////   //////////    
        ////////////////////////////    
        
        Copyright® The Workers Ltd. 
    -->
	
	
	<!-- 	    
	    # Overview
	    Magical image resizer and <img> tag generator, with fallback to DummyImage generator.
	    
	    ## Required params:
        - upload: takes an xPath of Symphony's upload node
            - if ulopad is omitted, it will generate a dummy image with the spacified dimensions (default 100x100px)
        
        ## Optional params:
        - w: the requested width
        - h: the requested height (both can be set)
        - (standard <img/> attributes. class, id, title, name, longdesc, etc.)
        - value-only: if set to either 'w' or 'h' will return only the result number not the whole <img/> tag.
        - mode: normal, fit
            - normal: w, h, w and h
            - fit: w and h
            
            - In normal mode the scaler takes whatever h and/or w is passed and scales the specified dimensions to whatever value was passed.  
            If either w or h are passed, then the missing value is derived proportionally. If both values are passed then both are applied, effectively constraining the image to a specified size.  
            In fit mode both h and w are required. The two values define the area within which the scaler has to proportionally fit the image.            
        - JITmode: JIT mode
        - JITcenter: JIT center
        - JITexternal: JIT external/internal switch
	    
	    ### Examples
	    
	    Output original size:
	    <xsl:call-template name="img">
	    <xsl:with-param name="upload" select="$upload"/>
	    </xsl:call-template>
	    
	    Force a specific size:
	    <xsl:call-template name="img">
	    <xsl:with-param name="upload" select="$upload"/>
	    <xsl:with-param name="w" select="300"/>
	    <xsl:with-param name="h" select="200"/>
	    </xsl:call-template>
	    
	    Scale proportionally based on width or height constraint:
	    <xsl:call-template name="img">
	    <xsl:with-param name="upload" select="$upload"/>
	    <xsl:with-param name="w" select="300"/>
	    </xsl:call-template>
	    
	    Scale proportionally within a set bounding box (square or not):
	    <xsl:call-template name="img">
	    <xsl:with-param name="upload" select="$upload"/>
	    <xsl:with-param name="mode" select="'fit'"/>
	    <xsl:with-param name="w" select="400"/>
	    <xsl:with-param name="h" select="400"/>
	    </xsl:call-template>
	    
	    Use and external image (w and h needed as we don't have XML metadata on the fetched image):
	    <xsl:call-template name="img">
	    <xsl:with-param name="JITexternal" select="'images.apple.com/home/images/mbp_hero20110224.png'"/>
	    <xsl:with-param name="w" select="400"/>
	    <xsl:with-param name="h" select="200"/>
	    </xsl:call-template>
	    
	    Generate a dummy image (needs Dummy Image extension)
	    <xsl:call-template name="img">
	    <xsl:with-param name="w" select="200"/>
	    <xsl:with-param name="h" select="150"/>
	    </xsl:call-template>
	    
	    Use it as a MATCHED template
	    <xsl:apply-templates match="upload" mode="magical.jit">
	    <xsl:with-param name="w" select="300"/>
	    </xsl:apply-templates>
	    
	    Add attributes (works in all modes)
	    <xsl:call-template name="img">
	    <xsl:with-param name="upload" select="$upload"/>
	    <xsl:with-param name="w" select="500"/>
	    <xsl:with-param name="class" select="'someclass anotherclass'"/>
	    <xsl:with-param name="id" select="'myID'"/>
	    <xsl:with-param name="title" select="'Herr Title'"/>
	    </xsl:call-template>
	    
	    
	    ### Notes
	    When this teamplate is used as a match rather than called by name, the DummyImage mode is effectively inaccessible.
	    Besides, it wouldn't make sense since you have a match, then you have an upload.
	    
	    
	    Copyright © The Workers Ltd.  
	    [theworkers.net][w]
	    [io@theworkers.net][io]
	    
	    [w]: http://theworkers.net/
	    [io]: mailto:io@theworkers.net
	-->
    
    <xsl:variable name="maxsize" select="2000"/>
    
    
    <!-- TMEPLATE -->
    <!-- Controller (use it NAMED or MATCHED)-->
    <xsl:template name="img" match="*" mode="magical.jit">
        <xsl:param name="upload" select="."/><!-- If not provided falls back to DummyImage extension -->
        <xsl:param name="value-only"/><!-- Require either w or h and it will only return the numeric value, not the whole <img/> tag -->
        <xsl:param name="mode" select="'normal'"/><!-- string: normal, fit, max  -->
        <xsl:param name="gridsize"/>
        <xsl:param name="JITmode" select="2"/>
        <xsl:param name="JITcenter" select="5"/>
        <xsl:param name="JITexternal"><!-- Scans the upload param for known files extensions. If found sets it as an external image URL -->
            <xsl:choose>
                <xsl:when test="(contains($upload, '.jpg') or
                                contains($upload, '.png')) and
                                not($upload/meta)">
                    <xsl:value-of select="$upload"/>
                </xsl:when>
                <xsl:otherwise><xsl:value-of select="0"/></xsl:otherwise>
            </xsl:choose>
        </xsl:param>
        
        <!-- <img/> attributes -->
        <xsl:param name="id"/>
        <xsl:param name="class"/>
        <xsl:param name="alt" select="'undefined'"/>
        <xsl:param name="name"/>
        <xsl:param name="longdesc"/>
        <xsl:param name="align"/>
        <xsl:param name="style"/>
        <xsl:param name="ismap"/>
        <xsl:param name="usemap"/>
        
        <!-- Requested w and/or h. Will either be used to force specific dims or as a bounding box in which to fit the resulting dims -->
        <xsl:param name="w"/>
        <xsl:param name="h"/>
        
        <!-- Root prefix (i.e. /cms/image/2/200...)-->
        <xsl:param name="root_prefix" select="substring-after(substring-after($root, 'http://'), '/')"/>
        <xsl:variable name="root"><!-- let's prepend the $root in case symphony is installed in a subdirectory -->
            <xsl:if test="$root_prefix != ''">
                <xsl:value-of select="concat('/', $root_prefix)"/>
            </xsl:if>
        </xsl:variable>
        
        <xsl:variable name="img_w">
                <xsl:call-template name="core-logic">
                    <xsl:with-param name="return" select="'w'"/>
                    <xsl:with-param name="upload" select="$upload"/>
                    <xsl:with-param name="mode" select="$mode"/>
                    <xsl:with-param name="w" select="$w"/>
                    <xsl:with-param name="h" select="$h"/>
                    <xsl:with-param name="gridsize" select="$gridsize"/>
                    <xsl:with-param name="JITexternal" select="$JITexternal"/>
                </xsl:call-template>
        </xsl:variable>
            
        <xsl:variable name="img_h">
                <xsl:call-template name="core-logic">
                    <xsl:with-param name="return" select="'h'"/>
                    <xsl:with-param name="upload" select="$upload"/>
                    <xsl:with-param name="mode" select="$mode"/>
                    <xsl:with-param name="w" select="$w"/>
                    <xsl:with-param name="h" select="$h"/>
                    <xsl:with-param name="gridsize" select="$gridsize"/>
                    <xsl:with-param name="JITexternal" select="$JITexternal"/>
                </xsl:call-template>
        </xsl:variable>
        
        <xsl:variable name="img_src">
            <xsl:choose>
                <xsl:when test="$JITexternal != 0">
                    <xsl:value-of select="concat($root, '/image/', $JITmode, '/', $img_w, '/', $img_h, '/', $JITcenter, '/1/', $JITexternal)"/>
                </xsl:when>
                <xsl:when test="$upload != ''">
                    <xsl:value-of select="concat($root, '/image/', $JITmode, '/', $img_w, '/', $img_h, '/', $JITcenter, '/', $JITexternal, $upload/@path, '/', $upload/filename)"/>
                </xsl:when>
                <xsl:when test="$upload = ''">
                    <xsl:value-of select="concat('/dummyimage/', $img_w, 'x', $img_h)"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>

        <xsl:if test="$value-only = 'w'">
            <xsl:value-of select="$img_w"/>
        </xsl:if>
        <xsl:if test="$value-only = 'h'">
            <xsl:value-of select="$img_h"/>
        </xsl:if>
        <xsl:if test="$value-only = ''">
            <xsl:call-template name="return-full-tag-with-attributes">
                <xsl:with-param name="src" select="$img_src"/>
                <xsl:with-param name="width" select="$img_w"/>
                <xsl:with-param name="height" select="$img_h"/>
                <xsl:with-param name="id" select="$id"/>
                <xsl:with-param name="class" select="$class"/>
                <xsl:with-param name="alt" select="$alt"/>
                <xsl:with-param name="name" select="$name"/>
                <xsl:with-param name="longdesc" select="$longdesc"/>
                <xsl:with-param name="align" select="$align"/>
                <xsl:with-param name="style" select="$style"/>
                <xsl:with-param name="ismap" select="$ismap"/>
                <xsl:with-param name="usemap" select="$usemap"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>



    <!-- TMEPLATE -->
    <!-- Width and Height Controller 
    Checks what mode we're in and passes/retrieves the right values for it -->
    <xsl:template name="core-logic">
        <xsl:param name="upload"/>
        <xsl:param name="return"/>
        <xsl:param name="mode"/>
        <xsl:param name="w"/>
        <xsl:param name="h"/>
        <xsl:param name="gridsize"/>
        <xsl:param name="JITexternal"/>
        
        <!-- the dimension currently being processed -->
        <xsl:variable name="current-dim">
            <xsl:choose>
                <xsl:when test="$return = 'w'">
                    <xsl:value-of select="$w"/>
                </xsl:when>
                <xsl:when test="$return = 'h'">
                    <xsl:value-of select="$h"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        
        <!-- the original width or height of the image -->
        <xsl:variable name="original-dim">
            <xsl:if test="$JITexternal = 0">
                <xsl:choose>
                    <xsl:when test="$return = 'w'">
                        <xsl:value-of select="$upload/meta/@width"/>
                    </xsl:when>
                    <xsl:when test="$return = 'h'">
                        <xsl:value-of select="$upload/meta/@height"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:if>
        </xsl:variable>
        
        <!-- Figure out ratio of original and compare to ratio of container if in 'fit' mode -->
        <xsl:variable name="original-ratio">
            <xsl:if test="$upload != ''">
                <xsl:if test="$JITexternal = 0">
                    <xsl:call-template name="wh_ratio">
                        <xsl:with-param name="upload" select="$upload"/>
                    </xsl:call-template>
                </xsl:if>
            </xsl:if>
        </xsl:variable>
        
        <xsl:variable name="fit-ratio">
            <xsl:if test="$w and $h">
                <xsl:call-template name="wh_ratio">
                    <xsl:with-param name="w" select="$w"/>
                    <xsl:with-param name="h" select="$h"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:variable>
        
        <!-- Modes -->
        <xsl:variable name="result">
            <xsl:choose>
                                
                <xsl:when test="$mode = 'normal'">
                    <xsl:choose>
                        <!-- When there's no upload param or a JITexternal, we use the w and h values passed directly as there is nothing to process -->
                        <xsl:when test="$JITexternal != 0">
                            <xsl:choose>
                                <xsl:when test="$w and $h">
                                    <xsl:value-of select="$current-dim"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:message>Magical JIT: if you are using an external image, you need to set both width and height. Also make sure you whitelisted the domain in Symphony's preferences</xsl:message>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:when test="$upload = '' and (not($w) or not($h))">
                            <xsl:message>Magical JIT: The "upload" param is empty. In this case we try to fall back to using the Dummy Image generator extension, but for that you'll need to pass both the height and width (e.g:<![CDATA[&lt;xsl:with-param name="w" select="400">]]>)</xsl:message>
                            <xsl:message>Check if you 'select' is correct or if using named template mode, make sure you are explicitly passing the 'upload' param.</xsl:message>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:call-template name="rescale">
                                <xsl:with-param name="upload" select="$upload"/>
                                <xsl:with-param name="return" select="$return"/>
                                <xsl:with-param name="w" select="$w"/>
                                <xsl:with-param name="h" select="$h"/>
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                
                <xsl:when test="$mode = 'max'">
                    <xsl:choose>
                        <xsl:when test="($upload/meta/@width &gt; $w) and ($w != '')">
                            <xsl:call-template name="rescale">
                                <xsl:with-param name="upload" select="$upload"/>
                                <xsl:with-param name="return" select="$return"/>
                                <xsl:with-param name="w" select="$w"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:when test="($upload/meta/@height &gt; $h) and ($h != '')">
                            <xsl:call-template name="rescale">
                                <xsl:with-param name="upload" select="$upload"/>
                                <xsl:with-param name="return" select="$return"/>
                                <xsl:with-param name="h" select="$h"/>
                            </xsl:call-template>
                        </xsl:when>
                        
                        <xsl:when test="(($upload/meta/@width &lt; $w) and ($w != '')) or (($upload/meta/@height &lt; $h) and ($h != ''))">
                            <xsl:value-of select="$original-dim"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:message>Magical JIT: When using 'max' mode you need to specify either width, height or both. For instance: <![CDATA[&lt;xsl:with-param name="w" select="400">]]></xsl:message>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                
                <xsl:when test="$mode = 'fit'">
                    <xsl:if test="$original-ratio &gt; $fit-ratio">
                        <xsl:call-template name="rescale">
                            <xsl:with-param name="upload" select="$upload"/>
                            <xsl:with-param name="return" select="$return"/>
                            <xsl:with-param name="w" select="$w"/>
                        </xsl:call-template>
                    </xsl:if>
                    <xsl:if test="$original-ratio &lt; $fit-ratio">
                        <xsl:call-template name="rescale">
                            <xsl:with-param name="upload" select="$upload"/>
                            <xsl:with-param name="return" select="$return"/>
                            <xsl:with-param name="h" select="$h"/>
                        </xsl:call-template>
                    </xsl:if>
                </xsl:when>
                
                <xsl:when test="$mode = 'trim'">
                    <xsl:call-template name="rescale">
                        <xsl:with-param name="upload" select="$upload"/>
                        <xsl:with-param name="return" select="$return"/>
                        <xsl:with-param name="w" select="$w"/>
                        <xsl:with-param name="h" select="$h"/>
                    </xsl:call-template>
                </xsl:when>
                
            </xsl:choose>
        </xsl:variable>
        
        <!-- before returning the final value, we check if there's any griddy settings -->
        <xsl:variable name="value">
            <xsl:choose>
                <xsl:when test="$mode = 'trim'">
                    <xsl:choose>
                        <xsl:when test="$gridsize">
                            <xsl:choose>
                                <xsl:when test="$current-dim != ''">
                                    <xsl:value-of select="$current-dim"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="round($result div $gridsize) * $gridsize"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:message> Magical JIT: When using <![CDATA[&lt;xsl:with-param name="mode" select="trim">]]> you also need to specify a grid size. Eg: <![CDATA[&lt;xsl:with-param name="gridsize" select="50">]]>  </xsl:message>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                
                <xsl:when test="$gridsize and not($mode = 'fit' or $mode = 'max')">
                    <xsl:value-of select="round($result) * $gridsize"/>
                </xsl:when>
                
                <xsl:otherwise>
                    <xsl:value-of select="$result"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- last sanity check to avoid massive memory swapping and crashing PHP -->
        <xsl:variable name="final">
            <xsl:choose>
                <xsl:when test="$value and ($value &lt;= $maxsize)">
                    <xsl:value-of select="$value"/>
                </xsl:when>
                <xsl:when test="$value = ''">
                    <xsl:message>Missing one value</xsl:message>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>Magical JIT: the image exceeds the maximum safe size. Depending on your server's RAM skillz you can change this setting in the Magical JIT Utility source.</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:value-of select="$final"/>
    </xsl:template>



    <!-- TMEPLATE -->
    <!-- Returns the Width/Height ratio. Used mainly in 'fit' mode to determine whether we have landscape or portrait format -->
    <xsl:template name="wh_ratio">
        <xsl:param name="upload"/>
        <xsl:param name="h" select="$upload/meta/@height"/>
        <xsl:param name="w" select="$upload/meta/@width"/>
        
        <xsl:variable name="ratio" select="$w div $h"/>
        <xsl:value-of select="$ratio"/>
    </xsl:template>



    <!-- TMEPLATE -->
    <!-- Calculates the missing dimension, retaining proportions. If both w and h values are empty it returns the original image size -->
    <xsl:template name="rescale">
        <xsl:param name="upload"/><!-- Required -->
        <xsl:param name="return"/><!-- Required. Takes 'w' or 'h' -->
        
        <!-- if none specified the original dims are returned -->
        <xsl:param name="h"/>
        <xsl:param name="w"/>        
        
        <xsl:variable name="original-h" select="$upload/meta/@height"/>
        <xsl:variable name="original-w" select="$upload/meta/@width"/>
        
        <xsl:variable name="derived-dim">
            <xsl:choose>
                <xsl:when test="$w">
                    <xsl:value-of select="($w div $original-w)* $original-h"/>
                </xsl:when>
                <xsl:when test="$h">
                    <xsl:value-of select="($h div $original-h)* $original-w"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="result">
            <xsl:choose>
                <xsl:when test="$return = 'w'">
                    <xsl:choose>
                        <xsl:when test="$w">
                            <xsl:value-of select="$w"/>
                        </xsl:when>
                        <xsl:when test="$h">
                            <xsl:value-of select="$derived-dim"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$original-w"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                
                <xsl:when test="$return = 'h'">
                    <xsl:choose>
                        <xsl:when test="$h">
                            <xsl:value-of select="$h"/>
                        </xsl:when>
                        <xsl:when test="$w">
                            <xsl:value-of select="$derived-dim"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$original-h"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:value-of select="round($result)"/>
    </xsl:template>
    
    
    
    <!-- TMEPLATE -->
    <!-- Iterates through all defined attributes and returns the full <img/> tag to the calling template -->
    <xsl:template name="return-full-tag-with-attributes">
        <xsl:param name="src"/>
        <xsl:param name="width"/>
        <xsl:param name="height"/>
        <xsl:param name="id"/>
        <xsl:param name="class"/>
        <xsl:param name="alt"/>
        <xsl:param name="name"/>
        <xsl:param name="title"/>
        <xsl:param name="longdesc"/>
        <xsl:param name="align"/>
        <xsl:param name="style"/>
        <xsl:param name="ismap"/>
        <xsl:param name="usemap"/>

        <xsl:variable name="nodeset">
            <attr name="src" value="{$src}"/>
            <attr name="width" value="{$width}"/>
            <attr name="height" value="{$height}"/>
            <attr name="id" value="{$id}"/>
            <attr name="class" value="{$class}"/>
            <attr name="alt" value="{$alt}"/>
            <attr name="name" value="{$name}"/>
            <attr name="title" value="{$title}"/>
            <attr name="longdesc" value="{$longdesc}"/>
            <attr name="align" value="{$align}"/>
            <attr name="style" value="{$style}"/>
            <attr name="ismap" value="{$ismap}"/>
            <attr name="usemap" value="{$usemap}"/>
        </xsl:variable>
        
        <img>
            <xsl:for-each select="exsl:node-set($nodeset)/attr[@value != '']">
                <xsl:attribute name="{@name}"><xsl:value-of select="@value"/></xsl:attribute>
            </xsl:for-each>
        </img>
        
    </xsl:template>

</xsl:stylesheet>