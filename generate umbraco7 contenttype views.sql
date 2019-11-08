DECLARE @filterAlias nvarchar(255) 
SET @filterAlias = 'document type alias(es)' 

DECLARE cAlias cursor for
SELECT DISTINCT dbo.cmsContentType.alias ,
         dbo.cmsContentType.nodeid 
FROM dbo.cmsContentType
INNER JOIN dbo.cmsPropertyTypeGroup
    ON dbo.cmsContentType.nodeId = dbo.cmsPropertyTypeGroup.contenttypeNodeId
INNER JOIN dbo.cmsPropertyType
    ON dbo.cmsPropertyTypeGroup.id = dbo.cmsPropertyType.propertyTypeGroupId
INNER JOIN dbo.cmsDataType
    ON dbo.cmsPropertyType.dataTypeId = dbo.cmsDataType.nodeId
INNER JOIN dbo.umbracoNode
    ON dbo.cmsContentType.nodeId = dbo.umbracoNode.id 						 
WHERE dbo.cmsContentType.alias  LIKE ISNULL(@filterAlias ,'%')
ORDER BY 1

DECLARE @alias NVARCHAR(255), @nodeObjectType NVARCHAR(100), @ctpk INT


OPEN cAlias
FETCH cAlias INTO @alias, @ctpk
WHILE @@FETCH_STATUS = 0 BEGIN

	PRINT 'IF OBJECT_ID(''dbo.V_' + @alias + ''', ''V'') IS NOT NULL DROP VIEW dbo.V_' + @alias + ';'
	PRINT 'GO'
	PRINT 'CREATE VIEW V_' + @alias + ' AS '
	PRINT 'SELECT 	dbo.umbracoNode.id AS __UNId, dbo.umbracoNode.text AS __UNText'	

	DECLARE @cAlias NVARCHAR(255), @cDbType NVARCHAR(255), @ptId INT

	DECLARE cColumn CURSOR FOR 
	SELECT	dbo.cmsPropertyType.Alias AS ptAlias, 
			dbo.cmsDataType.dbType, dbo.cmsPropertyType.Id as ptId
	FROM       dbo.cmsContentType 
	INNER JOIN dbo.cmsPropertyTypeGroup ON dbo.cmsContentType.nodeId = dbo.cmsPropertyTypeGroup.contenttypeNodeId 
	INNER JOIN dbo.cmsPropertyType ON dbo.cmsPropertyTypeGroup.id = dbo.cmsPropertyType.propertyTypeGroupId 
	INNER JOIN dbo.cmsDataType ON dbo.cmsPropertyType.dataTypeId = dbo.cmsDataType.nodeId 
	INNER JOIN dbo.umbracoNode ON dbo.cmsContentType.nodeId = dbo.umbracoNode.id
	WHERE dbo.cmsContentType.alias  = @alias
	ORDER BY dbo.cmsPropertyTypeGroup.sortorder, dbo.cmsPropertyType.sortOrder

	OPEN cColumn
	FETCH cColumn INTO @cAlias, @cDbType, @ptId
	while @@FETCH_STATUS = 0 begin

		PRINT ', cmsPropertyData_' + @cAlias + '.' +
			CASE @cDbType WHEN 'Decimal' THEN 'dataDecimal'
				WHEN 'Integer' THEN 'dataInt'
				WHEN 'Ntext' THEN 'dataNText'
				WHEN 'Nvarchar' THEN 'dataNVarchar'
				END + ' AS ' + @cAlias

		FETCH cColumn INTO @cAlias, @cDbType, @ptId
	END
	CLOSE cColumn

	PRINT 'FROM dbo.cmsDocument 
	INNER JOIN dbo.umbracoNode ON dbo.cmsDocument.nodeId = dbo.umbracoNode.id 
	INNER JOIN dbo.cmsContent ON dbo.cmsDocument.nodeid = dbo.cmsContent.nodeId AND dbo.cmsContent.contenttype = ' + CONVERT(NVARCHAR, @ctpk)

	OPEN cColumn
	FETCH cColumn INTO @cAlias, @cDbType, @ptId
	WHILE @@FETCH_STATUS = 0 begin

		PRINT 'LEFT OUTER JOIN  dbo.cmsPropertyData cmsPropertyData_' + @cAlias + ' 
			ON cmsPropertyData_' + @cAlias + '.versionId = dbo.cmsDocument.versionId AND cmsPropertyData_' 
				+ @cAlias + '.contentNodeId = dbo.cmsDocument.nodeId AND cmsPropertyData_' + @cAlias + '.propertytypeid = ' + CONVERT(NVARCHAR, @ptid)

		FETCH cColumn INTO @cAlias, @cDbType, @ptId
	END
	CLOSE cColumn
	DEALLOCATE cColumn

	PRINT 'WHERE dbo.cmsDocument.published = 1;'
	PRINT 'GO'

	FETCH cAlias INTO @alias, @ctpk
END
CLOSE cAlias
DEALLOCATE cAlias


