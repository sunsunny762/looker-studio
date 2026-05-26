/******  View [clickup].[vPeople] ******/
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[clickup].[vPeople]'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE VIEW [clickup].[vPeople] AS' 
END
GO
ALTER VIEW [clickup].[vPeople]
AS

  SELECT t.id, 
	t.name,
	cf_email.email as [email],
	cf_contacttitle.contacttitle AS [title],
	ISNULL(comp.name,cf_company.company) AS company,
	cf_leadsource.leadsource AS leadSource,
	cf_product.product AS product,
	cf_value.value AS taskValue,
	[Utilities].[EpochToDate](cf_contractstart.contractstart) AS contractStart,
	[Utilities].[EpochToDate](t.DateCreated) AS CreatedDate,
	CASE WHEN DATEDIFF(DAY,[Utilities].[EpochToDate](t.DateCreated),GETDATE()) < 7 THEN 'Less than 07 days'
		 WHEN DATEDIFF(DAY,[Utilities].[EpochToDate](t.DateCreated),GETDATE()) < 14 THEN 'Less than 14 days'
		 WHEN DATEDIFF(DAY,[Utilities].[EpochToDate](t.DateCreated),GETDATE()) < 28 THEN 'Less than 28 days'
		 WHEN DATEDIFF(DAY,[Utilities].[EpochToDate](t.DateCreated),GETDATE()) < 56 THEN 'Less than 56 days'
		 WHEN DATEDIFF(DAY,[Utilities].[EpochToDate](t.DateCreated),GETDATE()) < 84 THEN 'Less than 84 days'
		 ELSE 'More than 86 days'
		  END AS TimeSinceCreated,
	CASE WHEN t.DueDate IS NULL THEN NULL ELSE [Utilities].[EpochToDate](t.dueDate) END AS DueDate,
	CASE WHEN [Utilities].[EpochToDate](t.dueDate) < GETDATE() THEN 'Yes' ELSE 'No' END AS Overdue,
	ISNULL(ts.friendlyName,t.status) AS status,
	DATEDIFF(DAY,ISNULL(his.movedToStatus,[Utilities].[EpochToDate](t.DateCreated)),GETDATE()) AS timeInStatus,
	ts.description AS statusDescription,
	ts.category,
	ts.groupName,
	orderNo,
	u.name AS assignee,
	CASE WHEN cf_value.value IS NULL THEN '{Missing Value}' ELSE '' END +
	CASE WHEN t.dueDate IS NULL AND ISNULL(ts.friendlyName,t.status) NOT IN ('Unsubscribed') THEN '{Missing Due Date}' ELSE '' END +
	CASE WHEN cf_leadsource.leadsource IS NULL THEN '{Missing Lead Source}' ELSE '' END +
	CASE WHEN cf_product.product IS NULL THEN '{Missing Product}' ELSE '' END +
	CASE WHEN cf_contacttitle.contacttitle IS NULL THEN '{Missing Title}' ELSE '' END +
	CASE WHEN ISNULL(ts.friendlyName,t.status) = 'Active Customer' AND cert.id IS NULL THEN '{Missing Certification}' ELSE '' END +
	CASE WHEN u.name IS NULL THEN '{Missing Assignee}' ELSE '' END AS Exceptions,

	CASE WHEN cf_value.value IS NULL THEN 1 ELSE 0 END +
	CASE WHEN t.dueDate IS NULL AND ISNULL(ts.friendlyName,t.status) NOT IN ('Unsubscribed') THEN 1 ELSE 0 END +
	CASE WHEN cf_leadsource.leadsource IS NULL THEN 1 ELSE 0 END +
	CASE WHEN cf_product.product IS NULL THEN 1 ELSE 0 END +
	CASE WHEN cf_contacttitle.contacttitle IS NULL THEN 1 ELSE 0 END +
	CASE WHEN ISNULL(ts.friendlyName,t.status) = 'Active Customer' AND cert.id IS NULL THEN 1 ELSE 0 END +
	CASE WHEN u.name IS NULL THEN 1 ELSE 0 END AS ExceptionCount,
	pc.companyTaskId,
	cc.certificationTaskId,
	ISNULL(comp.name,cf_company.company) AS CompanyName
	   FROM clickup.Task t 
  LEFT JOIN clickup.TaskStatus ts ON t.status = ts.statusName
  LEFT JOIN (SELECT taskId,status, MAX(utilities.EpochToDate(dateCreated)) AS movedToStatus FROM clickup.StatusHistory GROUP BY taskId,status) his ON his.taskid = t.id AND his.[status] = t.[status]
  LEFT JOIN clickup.assignee a ON a.taskId = t.id
  LEFT JOIN clickup.[user] u ON u.id = a.userid
  LEFT JOIN clickup.personcompany pc ON pc.persontaskid = t.id
  LEFT JOIN clickup.task comp ON comp.id = pc.companytaskid
  LEFT JOIN clickup.companycertification cc ON cc.companytaskid = comp.id
  LEFT JOIN clickup.task cert ON cert.id = cc.certificationtaskid AND (cert.activeTo IS NULL OR [utilities].[EpochToDate](cert.activeTo) >= GETDATE())
    OUTER APPLY (
	SELECT [value] as [contractStart]
		FROM [clickup].[CustomField] cf 
	WHERE cf.[taskId] = cert.[id] AND cf.[name] = 'Contract Start'
) as cf_contractstart(contractstart)
  OUTER APPLY (
	SELECT [value] as [email]
		FROM [clickup].[CustomField] cf 
	WHERE cf.[taskId] = t.[id] AND cf.[name] = 'Email'
) as cf_email(email)
  OUTER APPLY (
	SELECT [value] as [company]
		FROM [clickup].[CustomField] cf 
	WHERE cf.[taskId] = t.[id] AND cf.[name] = 'Company Name'
) as cf_company(company)
  OUTER APPLY (
	SELECT [value] as [value]
		FROM [clickup].[CustomField] cf 
	WHERE cf.[taskId] = t.[id] AND cf.[name] = 'Current Task Value'
) as cf_value(value)
  OUTER APPLY (
	SELECT [value] as [leadsource]
		FROM [clickup].[CustomField] cf 
	WHERE cf.[taskId] = t.[id] AND cf.[name] = 'Lead Source'
) as cf_leadsource(leadsource)
  OUTER APPLY (
	SELECT [value] as [contacttitle]
		FROM [clickup].[CustomField] cf 
	WHERE cf.[taskId] = t.[id] AND cf.[name] = 'Contact Title'
) as cf_contacttitle(contacttitle) 
  OUTER APPLY (
	SELECT [value] as [product]
		FROM [clickup].[CustomField] cf 
	WHERE cf.[taskId] = t.[id] AND cf.[name] = 'Product'
) as cf_product(product)
  WHERE t.listid = 901201812211
    AND t.parentId IS NULL
	AND (t.activeTo IS NULL OR [utilities].[EpochToDate](t.activeTo) >= GETDATE())
	--AND t.id = '869407ekq'
GO


