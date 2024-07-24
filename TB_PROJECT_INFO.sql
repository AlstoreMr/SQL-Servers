SELECT A_TPTO.PROJECTID            AS '项目ID',
       S_APU.PROJECTNAME           AS '项目名称',
       A_TPTO.TASK_ID              AS '任务ID',
       A_TPTO.CONTENT              AS '任务标题',
       S_APU.Stage                 AS '项目Stage',
       S_APU.YANFA                 AS '研发事业部',
       S_APU.QIANTAI               AS '前台事业部',
       A_TTPTCO.CUSTOMFIELDS_TITLE AS '任务归属部门',
       A_TPTO.STARTDATE            AS '开始时间',
       A_TPTO.DUEDATE              AS '结束时间',
       A_TPTO.ACCOMPLISHTIME       AS '实际完成时间',
       A_TPCO.PLANNED_INTEGRAL     AS '计划积分',
       DTM.NAME                    AS '执行者',
       A_TPPWO.COMPLETED_TIME      AS '实际工时',
       A_TPPWO.NAME                AS '实际工时填写人'
FROM TB_MYSQL_ODS.TB_PROJECT_TASK_ODS AS A_TPTO
         LEFT JOIN
     DIM.DIM_TB_MEMBERS AS DTM
     ON
         A_TPTO.EXECUTORID = DTM.USERID
         LEFT JOIN (SELECT A.*,
                           B.YANFA,
                           C.QIANTAI
                    FROM (SELECT A_DTPU.PROJECTID,
                                 A_DTPU.PROJECTNAME,
                                 A_DTPU.STARTDATE,
                                 A_DTPU.ENDDATE,
                                 case
                                     when A_TPCO.NAME = 'Stage'
                                         THEN A_DTPU.CUSTOMFIELDS_CUSTOMFIELDID_TITLE
                                     END Stage
                          FROM DIM.DIM_TB_PROJECT_UNFOLD A_DTPU
                                   LEFT JOIN
                               TB_MYSQL_ODS.TB_PROJECT_CUSTOMFIELD_ODS AS A_TPCO
                               ON
                                   A_DTPU.CUSTOMFIELDS_CUSTOMFIELDID = A_TPCO.CUSTOMFIELD_ID
                          where A_TPCO.NAME = 'Stage') AS A
                             LEFT JOIN (SELECT A_DTPU.PROJECTID,
                                               A_DTPU.PROJECTNAME,
                                               A_DTPU.STARTDATE,
                                               A_DTPU.ENDDATE,
                                               CASE
                                                   WHEN A_TPCO.NAME = '事业部-研发'
                                                       THEN A_DTPU.CUSTOMFIELDS_CUSTOMFIELDID_TITLE
                                                   END YANFA
                                        FROM DIM.DIM_TB_PROJECT_UNFOLD A_DTPU
                                                 LEFT JOIN
                                             TB_MYSQL_ODS.TB_PROJECT_CUSTOMFIELD_ODS AS A_TPCO
                                             ON
                                                 A_DTPU.CUSTOMFIELDS_CUSTOMFIELDID = A_TPCO.CUSTOMFIELD_ID
                                        where A_TPCO.NAME = '事业部-研发') AS B
                                       ON
                                           A.PROJECTID = B.PROJECTID
                                               AND A.PROJECTNAME = B.PROJECTNAME
                                               AND A.STARTDATE = B.STARTDATE
                                               AND A.ENDDATE = B.ENDDATE
                             LEFT JOIN (SELECT A_DTPU.PROJECTID,
                                               A_DTPU.PROJECTNAME,
                                               A_DTPU.STARTDATE,
                                               A_DTPU.ENDDATE,
                                               case
                                                   when A_TPCO.NAME = '事业部-前台'
                                                       THEN A_DTPU.CUSTOMFIELDS_CUSTOMFIELDID_TITLE
                                                   END QIANTAI
                                        FROM DIM.DIM_TB_PROJECT_UNFOLD A_DTPU
                                                 LEFT JOIN
                                             TB_MYSQL_ODS.TB_PROJECT_CUSTOMFIELD_ODS AS A_TPCO
                                             ON A_DTPU.CUSTOMFIELDS_CUSTOMFIELDID = A_TPCO.CUSTOMFIELD_ID
                                        where A_TPCO.NAME = '事业部-前台') AS C
                                       ON
                                           A.PROJECTID = C.PROJECTID
                                               AND A.PROJECTNAME = C.PROJECTNAME
                                               AND A.STARTDATE = C.STARTDATE
                                               AND A.ENDDATE = C.ENDDATE) AS S_APU
                   ON
                       A_TPTO.PROJECTID = S_APU.PROJECTID
         LEFT JOIN (SELECT *
                    FROM test_tmp001.TMP_PROJECT_TASK_CUSTOMFIELD_OW
                    WHERE CUSTOMFIELD_NAME = '任务归属部门') AS A_TTPTCO
                   ON
                       A_TPTO.TASK_ID = A_TTPTCO.TASK_ID
         LEFT JOIN (SELECT U_TRRO.OBJECTID,
                           U_DTM.NAME,
                           ROUND(SUM(U_TRRO.WORKTIME / 3600000), 2) AS COMPLETED_TIME
                    -- 完成工时 （时间戳转换 求和，保留两位小数）
                    FROM TB_MYSQL_ODS.TB_PROJ_PROJECTTASKWORKTIME_ODS AS U_TRRO
                             LEFT JOIN
                         TB_MYSQL_ODS.TB_PROJECT_TASK_ODS AS U_TPTO
                         ON
                             U_TRRO.OBJECTID = U_TPTO.TASK_ID
                             LEFT JOIN
                         DIM.DIM_TB_MEMBERS AS U_DTM
                         ON
                             U_DTM.USERID = U_TRRO.USERID
                             left join
                         DIM.DIM_PROJECT_EXPAND_DA AS dped
                         ON
                             U_TPTO.PROJECTID = dped.PROJECTID
                    WHERE (
                        dped.ISSUSPENDED = FALSE
                            and (
                            dped.PROJECTTAGNAME LIKE '%概念项目%'
                                or dped.PROJECTTAGNAME LIKE '%预研项目%'
                                or dped.PROJECTTAGNAME LIKE '%在研项目%'
                                or dped.PROJECTTAGNAME LIKE '%量产项目%'
                                or dped.PROJECTTAGNAME LIKE '%软件项目%'
                                or dped.PROJECTTAGNAME LIKE '%部门积分项目%'
                            )
                        )
                       OR (
                        dped.ISSUSPENDED = true
                            and dped.stage is not null
                            and U_TPTO.ISDONE = true
                        )
                    GROUP BY U_TRRO.OBJECTID,
                             U_DTM.NAME) AS A_TPPWO
                   ON
                       A_TPTO.TASK_ID = A_TPPWO.OBJECTID
         LEFT JOIN (SELECT U_PTCO1.TASK_ID,
                           ROUND(sum(CAST(CUSTOMFIELDS_TITLE AS FLOAT)), 2) AS PLANNED_INTEGRAL
                    -- 计划积分 （字段类型转换 求和，保留两位小数）
                    FROM DWD.PROJECT_TASK_CUSTOMFIELD_OW AS U_PTCO1
                             LEFT JOIN
                         TB_MYSQL_ODS.TB_PROJECT_TASK_ODS AS U_TPTO
                         ON
                             U_PTCO1.TASK_ID = U_TPTO.TASK_ID
                             LEFT JOIN
                         DIM.DIM_PROJECT_EXPAND_DA AS dped
                         ON
                             U_PTCO1.PROJECTID = dped.PROJECTID
                    WHERE (
                        dped.ISSUSPENDED = FALSE
                            and (
                            dped.PROJECTTAGNAME LIKE '%概念项目%'
                                or dped.PROJECTTAGNAME LIKE '%预研项目%'
                                or dped.PROJECTTAGNAME LIKE '%在研项目%'
                                or dped.PROJECTTAGNAME LIKE '%量产项目%'
                                or dped.PROJECTTAGNAME LIKE '%软件项目%'
                                or dped.PROJECTTAGNAME LIKE '%部门积分项目%'
                            )
                        )
                       OR (
                        dped.ISSUSPENDED = true
                            and dped.stage is not null
                            and U_TPTO.ISDONE = true
                        )
                    GROUP BY U_PTCO1.TASK_ID) AS A_TPCO
                   ON
                       A_TPTO.TASK_ID = A_TPCO.TASK_ID