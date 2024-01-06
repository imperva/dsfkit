locals {
  mysql_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "logs:Describe*",
          "logs:List*",
          "rds:DescribeDBInstances",
          "logs:StartQuery",
          "logs:StopQuery",
          "logs:TestMetricFilter",
          "logs:FilterLogEvents",
          "logs:Get*",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "rds:DescribeDBClusters",
          "rds:DescribeOptionGroups"
        ],
        "Resource" : "*"
      }
    ]
  })
  postgres_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "logs:Describe*",
          "logs:List*",
          "rds:DescribeDBInstances",
          "logs:StartQuery",
          "logs:StopQuery",
          "logs:TestMetricFilter",
          "logs:FilterLogEvents",
          "logs:Get*",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "rds:DescribeDBClusters",
          "rds:DescribeOptionGroups"
        ],
        "Resource" : "*"
      }
    ]
  })

  mssql_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds:DescribeOptionGroups"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "VisualEditor1",
        "Effect" : "Allow",
        "Action" : [
          "s3:ListAllMyBuckets"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "VisualEditor2",
        "Effect" : "Allow",
        "Action" : [
          "s3:ListBucket",
          "s3:GetObject"
        ],
        "Resource" : "arn:aws:s3:::${var.database_details.db_identifier}-*" # bucket name starts with db_identifier prefix
      }
    ]
  })
}