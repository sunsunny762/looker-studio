/****** Add Column [clickup].[Task]  ******/
IF NOT EXISTS (SELECT *  FROM  sys.columns WHERE  object_id = OBJECT_ID(N'[clickup].[Task]') AND name = 'active')
	BEGIN
		ALTER TABLE [clickup].[Task] Add active bit
		ALTER TABLE [clickup].[Task] ADD  DEFAULT ((1)) FOR [active]
	END
GO

/******  StoredProcedure [clickup].[spClickup_AddStatusHistory] ******/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[clickup].[spClickup_AddStatusHistory]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [clickup].[spClickup_AddStatusHistory] AS' 
END
GO
ALTER PROCEDURE [clickup].[spClickup_AddStatusHistory]
	@taskId nvarchar(25)
	,@status_JSON nvarchar(max)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @status TABLE(
		[status] nvarchar(100),
		[type] nvarchar(100),
		[durationInMinutes] int
	)
	INSERT INTO @status ([status], [type], [durationInMinutes])
	SELECT ln.[status], ln.[type] , ln.[durationInMinutes]
	  FROM OPENJSON(@status_JSON) A
	CROSS APPLY OPENJSON(A.value) 
	WITH
	(
		[status] nvarchar(100),
		[type] nvarchar(100),
		[durationInMinutes] int
	) ln;

	MERGE [clickup].[statusHistory] cs
		USING @status s
	ON (cs.[taskId] = @taskId and s.[status] = cs.[status])
	--WHEN MATCHED
		-- THEN do nothing
	WHEN NOT MATCHED BY TARGET
		THEN INSERT ([taskId], [status], [type], [dateCreated] ,[durationInMinutes])
			 VALUES (@taskId, s.[status], s.[type], Utilities.DateToEpochTZ(null), s.[durationInMinutes])
	--WHEN NOT MATCHED BY SOURCE AND cs.taskId = @taskId
		--THEN do nothing
	;

	Return 1;
END
GO

/******  StoredProcedure [clickup].[spClickup_GetAllParentTasks] ******/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[clickup].[spClickup_GetAllParentTasks]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [clickup].[spClickup_GetAllParentTasks] AS' 
END
GO
ALTER PROCEDURE [clickup].[spClickup_GetAllParentTasks]
AS
BEGIN
	 SELECT * FROM [clickup].[Task] WHERE parentId is null
END
GO

/******  StoredProcedure [clickup].[spClickup_AddTasks] ******/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[clickup].[spClickup_AddTasks]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [clickup].[spClickup_AddTasks] AS' 
END
GO
ALTER PROCEDURE [clickup].[spClickup_AddTasks]
	@tasks_JSON nvarchar(max)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @tasks TABLE(
		[id] nvarchar(15), 
		[name] nvarchar(250),
		[description] nvarchar(MAX), 
		[parentId] nvarchar(15),
		[folderId] bigint,
		[listId]bigint,
		[spaceId] bigint,
		[status] nvarchar(50),
		[createdBy] int,
		[startDate] bigint,
		[dueDate] bigint,
		[dateCreated] bigint,
		[dateUpdated] bigint,
		[dateDone] bigint,
		[isArchived] bit,
		[status_JSON] nvarchar(max),
		[creator_JSON] nvarchar(max),
		[assignees_JSON] nvarchar(max),
		[customFields_JSON] nvarchar(max)
	)
	INSERT INTO @tasks ([id], [name], [description], [parentId], [folderId], [listId], [spaceId], [status], [createdBy], [startDate], [dueDate], [dateCreated], 
											[dateUpdated], [dateDone], [isArchived], [status_JSON], [creator_JSON], [assignees_JSON], [customFields_JSON])
	SELECT ln.[id], ln.[name], ln.[description], ln.[parentId], ln.[folderId], ln.[listId], ln.[spaceId], ln.[status], ln.[createdBy], ln.[startDate], ln.[dueDate],
					ln.[dateCreated], ln.[dateUpdated], ln.[dateDone], ln.[isArchived], ln.[status_JSON], ln.[creator_JSON], ln.[assignees_JSON], ln.[customFields_JSON]
	  FROM OPENJSON(@tasks_JSON) A
	CROSS APPLY OPENJSON(A.value) 
	WITH
	(
		[id] nvarchar(15), 
		[name] nvarchar(250),
		[description] nvarchar(MAX), 
		[parentId] nvarchar(15),
		[folderId] bigint,
		[listId]bigint,
		[spaceId] bigint,
		[status] nvarchar(50),
		[createdBy] int,
		[startDate] bigint,
		[dueDate] bigint,
		[dateCreated] bigint,
		[dateUpdated] bigint,
		[dateDone] bigint,
		[isArchived] bit,
		[status_JSON] nvarchar(max),
		[creator_JSON] nvarchar(max),
		[assignees_JSON] nvarchar(max),
		[customFields_JSON] nvarchar(max)
	) ln;

	MERGE [clickup].[Task] ct
		USING @tasks t
	ON (t.[id] = ct.[id])
	WHEN MATCHED
		THEN UPDATE
				SET ct.[name] = t.[name]
					,ct.[description] = t.[description]
					,ct.[status] = t.[status]
					,ct.[startDate] = t.[startDate]
					,ct.[dueDate] = t.[dueDate]
					,ct.[dateCreated] = t.[dateCreated]
					,ct.[dateUpdated] = t.[dateUpdated]
					,ct.[dateDone] = t.[dateDone]
					,ct.[isArchived] = t.[isArchived]
					,ct.[parentId] = t.[parentId]
					,ct.[folderId] = t.[folderId]
					,ct.[listId] = t.[listId]
					,ct.[spaceId] = t.[spaceId]
	WHEN NOT MATCHED BY TARGET
		THEN INSERT ([id], [name], [description], [parentId], [folderId], [listId], [spaceId], [status], [createdBy], [startDate], [dueDate], [dateCreated], [dateUpdated], [dateDone], [isArchived])
			 VALUES (t.[id], t.[name], t.[description], t.[parentId], t.[folderId], t.[listId], t.[spaceId], t.[status], t.[createdBy], t.[startDate], t.[dueDate], t.[dateCreated], t.[dateUpdated], t.[dateDone], t.[isArchived])
	--WHEN NOT MATCHED BY SOURCE AND ct.taskId = t.[id]
		--THEN DELETE
	;

	-- For each tasks, add assignees and custom fields
	DECLARE @taskId nvarchar(50)
	DECLARE @assignees_JSON nvarchar(max)
	DECLARE @creator_JSON nvarchar(max)
	DECLARE @status_JSON nvarchar(max)
	DECLARE @customFields_JSON nvarchar(max)
	DECLARE cur CURSOR for
		SELECT [id], [assignees_JSON], [creator_JSON], [status_JSON], [customFields_JSON] FROM @tasks
	OPEN cur
	FETCH NEXT FROM cur INTO @taskId, @assignees_JSON, @creator_JSON, @status_JSON, @customFields_JSON
	WHILE @@FETCH_STATUS = 0 BEGIN
				EXEC [clickup].[spClickup_AddAssignees] @taskId, @assignees_JSON
				EXEC [clickup].[spClickup_AddUsers] @assignees_JSON
				EXEC [clickup].[spClickup_AddUsers] @creator_JSON
				EXEC [clickup].[spClickup_AddCustomFields] @taskId, @customFields_JSON
			FETCH NEXT FROM cur INTO @taskId, @assignees_JSON, @creator_JSON, @status_JSON, @customFields_JSON
	END
	CLOSE cur
	DEALLOCATE cur

	Return 1;
END
GO


/******  StoredProcedure [clickup].[spClickup_AddStatusHistory] ******/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[clickup].[spClickup_AddStatusHistory]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [clickup].[spClickup_AddStatusHistory] AS' 
END
GO
ALTER PROCEDURE [clickup].[spClickup_AddStatusHistory]
	 @taskId nvarchar(25)
	,@status_JSON nvarchar(max)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @status TABLE(
		[status] nvarchar(100),
		[type] nvarchar(100),
		[durationInMinutes] int,
		[dateCreated] bigint
	)
	INSERT INTO @status ([status], [type], [durationInMinutes] ,[dateCreated])
	SELECT ln.[status], ln.[type] , ln.[durationInMinutes] , ln.[dateCreated]
	  FROM OPENJSON(@status_JSON) A
	CROSS APPLY OPENJSON(A.value) 
	WITH
	(
		[status] nvarchar(100),
		[type] nvarchar(100),
		[durationInMinutes] int,
		[dateCreated] bigint
	) ln;

	MERGE [clickup].[statusHistory] cs
		USING @status s
	ON (cs.[taskId] = @taskId and s.[status] = cs.[status])
	--WHEN MATCHED
		-- THEN do nothing
	WHEN NOT MATCHED BY TARGET
		THEN INSERT ([taskId], [status], [type], [dateCreated] ,[durationInMinutes])
			 VALUES (@taskId, s.[status], s.[type], s.[dateCreated], s.[durationInMinutes])
	--WHEN NOT MATCHED BY SOURCE AND cs.taskId = @taskId
		--THEN do nothing
	;

	Return 1;
END
GO
