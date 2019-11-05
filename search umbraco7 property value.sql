
DECLARE @searchString NVARCHAR(200) = 'searchTerm'

DECLARE @searchPattern NVARCHAR(210) = N'%' + @searchString + N'%'

-- https://stackoverflow.com/questions/32100769/get-the-node-url-from-the-umbraco-4-7-database

; WITH PathXml AS (
    /* -- This just gives nodes with their 'urlName' property
       -- not in recycle bin, 
       -- level > 1 which excludes the top level documents which are not  included in the url */
    SELECT nodeId
        , CAST([xml] AS XML).query('data(//@urlName[1])').value('.', 'varchar(max)') AS Path
    FROM cmsContentXml x
    JOIN umbracoNode n ON x.nodeId = n.id AND n.trashed = 0 AND n.level > 1
),
CVer AS (
	SELECT cv.ContentId
		, cv.VersionId
		, cv.VersionDate
		, ROW_NUMBER() OVER (PARTITION BY cv.ContentId ORDER BY cv.VersionDate DESC) AS rn
	FROM cmsContentVersion cv
)
SELECT
    un.id,
    un.path,
    '/' +     							/* IsNull after the leading '/'. This will handle the top level document */
    ISNULL((SELECT pl.Path + '/'  		/* Ok to end with a / */
             FROM PathXml pl           	/* e.g. ',-1,1071,1072,1189,' LIKE '%,1072,%' */
             WHERE ',' + un.path + ',' LIKE '%,' + CAST(pl.nodeId AS VARCHAR(MAX)) + ',%'
										/* order by the position of ',1072,' in ',-1,1071,1072,1189,' */
             ORDER BY CHARINDEX(',' + CAST(pl.nodeId AS VARCHAR(MAX)) + ',',
                                ',' + un.path + ',')
             FOR XML PATH('')), 
    '') AS Url,
    un.text PageName,
	data.Name, data.Alias, data.[dataNvarchar], data.dataNtext
FROM umbracoNode un
INNER JOIN CVer ON un.id = cver.ContentId AND cver.rn = 1	
	-- https://thesitedoctor.co.uk/blog/view-the-property-values-in-sql-for-latest-version-of-a-page-in-umbraco/
INNER JOIN  (
	SELECT pd.[id]
		,[contentNodeId]
		,[versionId]
		,[propertytypeid]
		,pt.Name, pt.Alias
		,[dataInt]
		,[dataDate]
		,[dataNvarchar]
		,[dataNtext]
	FROM [dbo].[cmsPropertyData] pd
	INNER JOIN [dbo].[cmsPropertyType] pt ON pd.propertytypeid = pt.id
	WHERE ([dataNvarchar] LIKE @searchPattern) OR ([dataNText] LIKE @searchpattern)
) data
ON data.contentNodeId = un.id AND data.versionId = cver.VersionId
WHERE un.trashed = 0
ORDER BY 3 								/* Url */
