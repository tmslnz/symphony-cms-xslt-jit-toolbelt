<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:exsl="http://exslt.org/common" xmlns:dyn="http://exslt.org/dynamic" extension-element-prefixes="exsl dyn">
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
    Magical Image Resize Utility
    ============================
    
    By The Workers London Ltd. 
    
    # Overview
    Magical image resizer and <img/> tag generator, with fallback to DummyImage extension.
    Suitable for call-template as well as apply-templates. Buyah.
        
    ## Params:
    - upload: takes an Result Tree Fragment of Symphony's <upload> or a URI to a local file.
    - external: takes an URL of a remote image without the "http://" part. If both $upload and $external are present, $external takes precedence.
    - w: the desired width
    - h: the desired height
    - value-only: if set to either 'w' or 'h' will return only the resulting dimension not the whole <img/> tag.
    - mode: 'normal', 'fit', 'max', 'trim'.
        'normal' (default). No value: original size. One value: proportional scaling. Two values: force scale. (none, w or h, w + h) 
        'fit' uses w and h to define a bouding box to which images will fit proportionally. (w + h)
        'max' shrinks the image only if an original dimension tops the desired max w or h (w or h, w + h)
        'trim' floors any derived value to a set grid interval. (w or h)
    - gridsize: the size of the grid. When in 'normal' (default) mode, w and h are to be considered as grid multipliers.
    - JITmode: JIT modes 0 to 3 (see docs on Symphony-CMS.com) 
    - JITcenter: JIT center 1 to 9
    - Standard <img/> attributes: class, id, title, name, longdesc, etc.
    

    See README for usage examples.
    
	-->
    
    <xsl:variable name="maxsize" select="2000"/>
    
    
    <!-- TMEPLATE ///////////////////////////////////////////////////////// -->
    <!-- Controller (use it NAMED or MATCHED)-->
    <xsl:template name="img" match="*" mode="img">
        <xsl:param name="upload" select="."/><!-- Must be a Result Tree Fragment (RTF). If empty falls back to DummyImage extension -->
        <xsl:param name="external"/><!-- takes an URL string of the desired image -->
        <xsl:param name="value-only"/><!-- Require either w or h and it will only return the numeric value, not the whole <img/> tag -->
        <xsl:param name="mode" select="'normal'"/><!-- string: normal, fit, max  -->
        <xsl:param name="gridsize"/>
        <xsl:param name="JITmode" select="2"/>
        <xsl:param name="JITcenter" select="5"/>
        
        
        <!-- <img/> attributes -->
        <xsl:param name="id"/>
        <xsl:param name="class"/>
        <xsl:param name="alt">
            <xsl:choose>
                <xsl:when test="$upload/filename">
                    <xsl:value-of select="$upload/filename"/>
                </xsl:when>
                <xsl:otherwise><xsl:value-of select="'undefined'"/></xsl:otherwise>
            </xsl:choose>
        </xsl:param>
        <xsl:param name="name"/>
        <xsl:param name="title"/>
        <xsl:param name="longdesc"/>
        <xsl:param name="align"/>
        <xsl:param name="style"/>
        <xsl:param name="ismap"/>
        <xsl:param name="usemap"/>
        
        <!-- Requested w and/or h. Will either be used to force specific dims
        or as a bounding box in which to fit the resulting dims -->
        <xsl:param name="w"/>
        <xsl:param name="h"/>
        
        <!-- Original W/H. Can either be passed directly or fall-back to the following defaults. Never go without it.-->
        <xsl:param name="source-w"/>
        <xsl:param name="source-h"/>
        
        
        <!-- Symphony Root prefix (i.e. /cms/image/2/200...)-->
        <xsl:param name="root_prefix" select="substring-after(substring-after($root, 'http://'), '/')"/>        
        <xsl:variable name="root"><!-- let's prepend the $root in case symphony is installed in a subdirectory -->
            <xsl:if test="$root_prefix != ''">
                <xsl:value-of select="concat('/', $root_prefix)"/>
            </xsl:if>
        </xsl:variable>
        
        <xsl:variable name="non-standard-upload">
            <!-- TODO: implement check for leading slash.
                If not found, add it.  -->
        </xsl:variable>
        
        <xsl:variable name="original-w">
            <xsl:choose>
                <xsl:when test="not($source-w)">
                    <xsl:choose>
                        <xsl:when test="$upload/meta/@width">
                            <xsl:value-of select="$upload/meta/@width"/>
                        </xsl:when>
                        <xsl:when test="$w">
                            <xsl:value-of select="$w"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$source-w"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        
        <xsl:variable name="original-h">
            <xsl:choose>
                <xsl:when test="not($source-h)">
                    <xsl:choose>
                        <xsl:when test="$upload/meta/@height">
                            <xsl:value-of select="$upload/meta/@height"/>
                        </xsl:when>
                        <xsl:when test="$h">
                            <xsl:value-of select="$h"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$source-h"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- Minimal error checking -->
        <xsl:choose>
            <xsl:when test="$mode = 'trim' and $gridsize = ''">
                <xsl:message>When using <![CDATA[&lt;xsl:with-param name="mode" select="trim">]]> you also need to specify a grid size. Eg: <![CDATA[&lt;xsl:with-param name="gridsize" select="50">]]>  </xsl:message>
            </xsl:when>
            <xsl:when test="$mode = 'max' and ($w = '' and $h = '')">
                <xsl:message>When using 'max' mode you need to specify either width, height or both. For instance: <![CDATA[&lt;xsl:with-param name="w" select="400">]]></xsl:message>
            </xsl:when>
        </xsl:choose>
        
        <xsl:choose>
            <!-- If neither $upload or $external are there, then we default to Dummy Image but we need the following: -->
            <xsl:when test="$upload = '' and $external = '' and (($original-w = '' and $w = '') or ($original-h = '' and $h=''))">
                <xsl:message>Dummy Image mode needs both W and H params if original-W and original-H are not passed</xsl:message>
            </xsl:when>
            <!-- If $external is set then we also need some sizing info -->
            <xsl:when test="$external != '' and (($original-w = '' and $w = '') or ($original-h = '' and $h = ''))">
                <xsl:message>When using external images, we need the original dims passed or both the desired width and height.</xsl:message>
            </xsl:when>
            <!-- If non of these are set it and the previous tests have passed, then $upload has data, but it's non-standard and we need-->
            <xsl:when test="$upload != '' and (($original-w = '' and $w = '') or ($original-h = '' and $h = ''))">
                <xsl:message>Cannot automatically determine original-w or original-h, please pass both explicitly if you are using a non-standard upload field</xsl:message>
            </xsl:when>
            <!-- Using non-standard upload field we also need to make sure we have a file path in $upload -->
            <xsl:when test="
                $upload != ''
                and
                not($upload/meta/@width) and not($upload/meta/@height)
                and not
                (
                    (substring(normalize-space($upload), string-length(normalize-space($upload))-3) = '.jpg')
                    or
                    (substring(normalize-space($upload), string-length(normalize-space($upload))-3) = '.png')
                )
                ">
                <xsl:message>The upload file path doesn't seem valid. It should end with .jpg or .png</xsl:message>
            </xsl:when>
        </xsl:choose>
        
        
        <!-- end possible cases -->
        
        <xsl:variable name="img_w">
                <xsl:call-template name="core-logic">
                    <xsl:with-param name="return"      select="'w'"/>
                    <xsl:with-param name="mode"        select="$mode"/>
                    <xsl:with-param name="w"           select="$w"/>
                    <xsl:with-param name="h"           select="$h"/>
                    <xsl:with-param name="original-w"  select="$original-w"/>
                    <xsl:with-param name="original-h"  select="$original-h"/>
                    <xsl:with-param name="gridsize"    select="$gridsize"/>
                </xsl:call-template>
        </xsl:variable>
            
        <xsl:variable name="img_h">
                <xsl:call-template name="core-logic">
                    <xsl:with-param name="return"      select="'h'"/>
                    <xsl:with-param name="mode"        select="$mode"/>
                    <xsl:with-param name="w"           select="$w"/>
                    <xsl:with-param name="h"           select="$h"/>
                    <xsl:with-param name="original-w"  select="$original-w"/>
                    <xsl:with-param name="original-h"  select="$original-h"/>
                    <xsl:with-param name="gridsize"    select="$gridsize"/>
                </xsl:call-template>
        </xsl:variable>
        
        <xsl:variable name="img_src">
            <xsl:choose>
                <xsl:when test="$external != ''">
                    <xsl:value-of select="concat($root, '/image/', $JITmode, '/', $img_w, '/', $img_h, '/', $JITcenter, '/1/', $external)"/>
                </xsl:when>
                <xsl:when test="$upload/@path and $upload/filename">
                    <xsl:value-of select="concat($root, '/image/', $JITmode, '/', $img_w, '/', $img_h, '/', $JITcenter, '/0', $upload/@path, '/', $upload/filename)"/>
                </xsl:when>
                <xsl:when test="$upload != ''">
                    <xsl:value-of select="concat($root, '/image/', $JITmode, '/', $img_w, '/', $img_h, '/', $JITcenter, '/0', $upload)"/>
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
    

    
    <!-- TMEPLATE ///////////////////////////////////////////////////////// -->
    <!-- Width and Height Controller 
    Checks what mode we're in and passes/retrieves the right values for it -->
    <xsl:template name="core-logic">
        <xsl:param name="return"/>
        <xsl:param name="mode"/>
        <xsl:param name="w"/>
        <xsl:param name="h"/>
        <xsl:param name="original-w"/>
        <xsl:param name="original-h"/>
        <xsl:param name="gridsize"/>
        
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
                <xsl:choose>
                    <xsl:when test="$return = 'w'">
                        <xsl:value-of select="$original-w"/>
                    </xsl:when>
                    <xsl:when test="$return = 'h'">
                        <xsl:value-of select="$original-h"/>
                    </xsl:when>
                </xsl:choose>
        </xsl:variable>
        
        
        <!-- Figure out ratio of original and compare to ratio of container if in 'fit' mode -->
        <xsl:variable name="original-ratio" select="$original-w div $original-h"/>


        <xsl:variable name="fit-ratio">
            <xsl:if test="$w and $h">
                <xsl:value-of select="$w div $h"/>
            </xsl:if>
        </xsl:variable>
        
        
        <!-- Modes -->
        <xsl:variable name="result">
            <xsl:choose>
                <xsl:when test="$mode = 'max'">
                    <xsl:choose>
                        <xsl:when test="(($original-w &gt; $w) and ($w != '')) or (($original-h &gt; $h) and ($h != ''))">
                            <xsl:call-template name="rescale">
                                <xsl:with-param name="return" select="$return"/>
                                <xsl:with-param name="w" select="$w"/>
                                <xsl:with-param name="h" select="$h"/>
                                <xsl:with-param name="original-w"  select="$original-w"/>
                                <xsl:with-param name="original-h"  select="$original-h"/>
                            </xsl:call-template>
                        </xsl:when>
                        
                        <xsl:otherwise><!-- Used to be test="(($original-w &lt; $w) and ($w != '')) or (($original-h &lt; $h) and ($h != ''))" -->
                            <xsl:value-of select="$original-dim"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                
                <xsl:when test="$mode = 'fit'">
                    <xsl:if test="$original-ratio &gt;= $fit-ratio">
                        <xsl:call-template name="rescale">
                            <xsl:with-param name="return" select="$return"/>
                            <xsl:with-param name="w" select="$w"/>
                            <xsl:with-param name="original-w"  select="$original-w"/>
                            <xsl:with-param name="original-h"  select="$original-h"/>
                        </xsl:call-template>
                    </xsl:if>
                    <xsl:if test="$original-ratio &lt; $fit-ratio">
                        <xsl:call-template name="rescale">
                            <xsl:with-param name="return" select="$return"/>
                            <xsl:with-param name="h" select="$h"/>
                            <xsl:with-param name="original-w"  select="$original-w"/>
                            <xsl:with-param name="original-h"  select="$original-h"/>
                        </xsl:call-template>
                    </xsl:if>
                </xsl:when>
                
                <xsl:otherwise>
                    <xsl:call-template name="rescale">
                        <xsl:with-param name="return" select="$return"/>
                        <xsl:with-param name="w" select="$w"/>
                        <xsl:with-param name="h" select="$h"/>
                        <xsl:with-param name="original-w"  select="$original-w"/>
                        <xsl:with-param name="original-h"  select="$original-h"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- before returning the final value, we check if there's any griddy settings -->
        <xsl:variable name="value">
            <xsl:choose>
                <xsl:when test="$mode = 'trim'">
                    <xsl:choose>
                        <xsl:when test="$current-dim != ''">
                            <xsl:value-of select="$current-dim"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="round($result div $gridsize) * $gridsize"/>
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
                    <xsl:choose>
                        <xsl:when test="$return = 'w'">
                            <xsl:message>Width has not been calculated</xsl:message>
                        </xsl:when>
                        <xsl:when test="$return = 'h'">
                            <xsl:message>Height has not been calculated</xsl:message>
                        </xsl:when>
                    </xsl:choose>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:value-of select="$final"/>
    </xsl:template>
    

    
    <!-- TMEPLATE ///////////////////////////////////////////////////////// -->
    <!-- Calculates the missing dimension, retaining proportions.
    If both w and h values are empty it returns the original image size -->
    
    <xsl:template name="rescale">
        <xsl:param name="return"/><!-- Required. Takes 'w' or 'h' -->
        
        <!-- if none specified the original dims are returned -->
        <xsl:param name="h"/>
        <xsl:param name="w"/>        
        <xsl:param name="original-h"/>
        <xsl:param name="original-w"/>
        
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
    
    
    
    
    <!-- TMEPLATE ///////////////////////////////////////////////////////// -->
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