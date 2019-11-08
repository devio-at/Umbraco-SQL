
DECLARE @searchString NVARCHAR(200) = 'searchTerm'

DECLARE @searchPattern NVARCHAR(210) = N'%' + @searchString + N'%'

; 
WITH PathXml AS (
		SELECT id, text AS path FROM [dbo].umbracoNode
		WHERE id > -1
	)
SELECT
    un.id,
    un.path,
    '/' + 
    ISNULL((SELECT pl.Path + '/'  /* Ok to end with a / */
             FROM PathXml pl 
             /* e.g. ',-1,1071,1072,1189,' LIKE '%,1072,%' */
             WHERE ',' + un.path + ',' LIKE '%,' + CAST(pl.id AS VARCHAR(MAX)) + ',%'
             /* order by the position of ',1072,' in ',-1,1071,1072,1189,' */
             ORDER BY CHARINDEX(',' + CAST(pl.id AS VARCHAR(MAX)) + ',',
                                ',' + un.path + ',')

             FOR XML PATH('')), 
    '') AS Path,
    un.text PageName,
	data.Name, data.Alias, data.varcharValue, data.textValue
FROM [dbo].umbracoNode un
INNER JOIN  (
	SELECT pd.[id]
		, cv.nodeId	
		,[versionId]
		,[propertytypeid]
		, pt.Name, pt.Alias
		,intValue
		,dateValue
		,varcharValue
		,textValue
	FROM [dbo].umbracoPropertyData pd
	INNER JOIN [dbo].[cmsPropertyType] pt ON pd.propertytypeid = pt.id
	INNER JOIN [dbo].[umbracoContentVersion] cv ON pd.versionId = cv.id AND cv.[current] = 1
	WHERE (varcharValue LIKE @searchPattern) or (textValue LIKE @searchpattern)
) data
ON data.nodeId = un.id 
WHERE un.trashed = 0
ORDER BY 3 /* Url */
