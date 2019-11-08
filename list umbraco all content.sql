
WITH rec AS (
	SELECT un.id, un.parentId, un.level, un.sortorder, CAST(un.text AS NVARCHAR(4000)) path, un.[nodeObjectType]
	FROM umbracoNode un
	WHERE un.id > 0 AND un.parentId = -1
	AND un.nodeObjectType = 'C66BA18E-EAF3-4CFF-8A22-41B16D66A972'

	UNION ALL

	SELECT un.id, un.parentId, un.level, un.sortorder, CAST(rec.path + N' / ' + un.text AS NVARCHAR(4000)), un.[nodeObjectType]
	FROM umbracoNode un
	INNER JOIN rec ON rec.id = un.parentId
	WHERE un.level < 10

)
SELECT * FROM rec

