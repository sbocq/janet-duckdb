(import ../src/db)
(import ../src/result)

(use judge)

# FROM: https://duckdb.org/2025/06/27/discovering-w-github.html

(comment # Commented out because we don't want to call Github each time we run `judge`

  # Note that these API calls will fail spuriously with a 403 if Github credentials are not set as
  # explained in the article (Github seems to do aggressive rate limiting if they are not provided).

  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]

      (with [result (db/query conn `
            SELECT
                *
            FROM
                read_json('https://api.github.com/search/repositories?q=duckdb&per_page=3')
          `)]
        (test (result/rows-changed result) 0)
        (test (result/describe-columns result :logical-type true)
              {:column-count 3
               :column-names ["total_count"
                              "incomplete_results"
                              "items"]
               :column-types [:bigint
                              :bool
                              [:list
                               [:struct
                                {"allow_forking" :bool
                                 "archive_url" :varchar
                                 "archived" :bool
                                 "assignees_url" :varchar
                                 "blobs_url" :varchar
                                 "branches_url" :varchar
                                 "clone_url" :varchar
                                 "collaborators_url" :varchar
                                 "comments_url" :varchar
                                 "commits_url" :varchar
                                 "compare_url" :varchar
                                 "contents_url" :varchar
                                 "contributors_url" :varchar
                                 "created_at" :timestamp
                                 "default_branch" :varchar
                                 "deployments_url" :varchar
                                 "description" :varchar
                                 "disabled" :bool
                                 "downloads_url" :varchar
                                 "events_url" :varchar
                                 "fork" :bool
                                 "forks" :bigint
                                 "forks_count" :bigint
                                 "forks_url" :varchar
                                 "full_name" :varchar
                                 "git_commits_url" :varchar
                                 "git_refs_url" :varchar
                                 "git_tags_url" :varchar
                                 "git_url" :varchar
                                 "has_discussions" :bool
                                 "has_downloads" :bool
                                 "has_issues" :bool
                                 "has_pages" :bool
                                 "has_projects" :bool
                                 "has_wiki" :bool
                                 "homepage" :varchar
                                 "hooks_url" :varchar
                                 "html_url" :varchar
                                 "id" :bigint
                                 "is_template" :bool
                                 "issue_comment_url" :varchar
                                 "issue_events_url" :varchar
                                 "issues_url" :varchar
                                 "keys_url" :varchar
                                 "labels_url" :varchar
                                 "language" :varchar
                                 "languages_url" :varchar
                                 "license" [:struct
                                            {"key" :varchar
                                             "name" :varchar
                                             "node_id" :varchar
                                             "spdx_id" :varchar
                                             "url" :varchar}]
                                 "merges_url" :varchar
                                 "milestones_url" :varchar
                                 "mirror_url" :varchar
                                 "name" :varchar
                                 "node_id" :varchar
                                 "notifications_url" :varchar
                                 "open_issues" :bigint
                                 "open_issues_count" :bigint
                                 "owner" [:struct
                                          {"avatar_url" :varchar
                                           "events_url" :varchar
                                           "followers_url" :varchar
                                           "following_url" :varchar
                                           "gists_url" :varchar
                                           "gravatar_id" :varchar
                                           "html_url" :varchar
                                           "id" :bigint
                                           "login" :varchar
                                           "node_id" :varchar
                                           "organizations_url" :varchar
                                           "received_events_url" :varchar
                                           "repos_url" :varchar
                                           "site_admin" :bool
                                           "starred_url" :varchar
                                           "subscriptions_url" :varchar
                                           "type" :varchar
                                           "url" :varchar
                                           "user_view_type" :varchar}]
                                 "private" :bool
                                 "pulls_url" :varchar
                                 "pushed_at" :timestamp
                                 "releases_url" :varchar
                                 "score" :double
                                 "size" :bigint
                                 "ssh_url" :varchar
                                 "stargazers_count" :bigint
                                 "stargazers_url" :varchar
                                 "statuses_url" :varchar
                                 "subscribers_url" :varchar
                                 "subscription_url" :varchar
                                 "svn_url" :varchar
                                 "tags_url" :varchar
                                 "teams_url" :varchar
                                 "topics" [:list :varchar]
                                 "trees_url" :varchar
                                 "updated_at" :timestamp
                                 "url" :varchar
                                 "visibility" :varchar
                                 "watchers" :bigint
                                 "watchers_count" :bigint
                                 "web_commit_signoff_required" :bool}]]]})

        (let [columns (result/fetch-columns result)]
          (test columns
                {:column @column-from-name
                 :column-count 3
                 :column-names ["total_count"
                                "incomplete_results"
                                "items"]
                 :column-types [:bigint :bool :list]
                 :columns @[@[3979]
                            @[false]
                            @[@[{:allow_forking true
                                 :archive_url "https://api.github.com/repos/duckdb/duckdb/{archive_format}{/ref}https://api.github.com/repos/duckdb/duckdb-web/{archive_format}{/ref}https://api.github.com/repos/davidgasquez/awesome-duckdb/{archive_format}{/ref}"
                                 :archived false
                                 :assignees_url "https://api.github.com/repos/duckdb/duckdb/assignees{/user}https://api.github.com/repos/duckdb/duckdb-web/assignees{/user}https://api.github.com/repos/davidgasquez/awesome-duckdb/assignees{/user}"
                                 :blobs_url "https://api.github.com/repos/duckdb/duckdb/git/blobs{/sha}https://api.github.com/repos/duckdb/duckdb-web/git/blobs{/sha}https://api.github.com/repos/davidgasquez/awesome-duckdb/git/blobs{/sha}"
                                 :branches_url "https://api.github.com/repos/duckdb/duckdb/branches{/branch}https://api.github.com/repos/duckdb/duckdb-web/branches{/branch}https://api.github.com/repos/davidgasquez/awesome-duckdb/branches{/branch}"
                                 :clone_url "https://github.com/duckdb/duckdb.githttps://github.com/duckdb/duckdb-web.githttps://github.com/davidgasquez/awesome-duckdb.git"
                                 :collaborators_url "https://api.github.com/repos/duckdb/duckdb/collaborators{/collaborator}https://api.github.com/repos/duckdb/duckdb-web/collaborators{/collaborator}https://api.github.com/repos/davidgasquez/awesome-duckdb/collaborators{/collaborator}"
                                 :comments_url "https://api.github.com/repos/duckdb/duckdb/comments{/number}https://api.github.com/repos/duckdb/duckdb-web/comments{/number}https://api.github.com/repos/davidgasquez/awesome-duckdb/comments{/number}"
                                 :commits_url "https://api.github.com/repos/duckdb/duckdb/commits{/sha}https://api.github.com/repos/duckdb/duckdb-web/commits{/sha}https://api.github.com/repos/davidgasquez/awesome-duckdb/commits{/sha}"
                                 :compare_url "https://api.github.com/repos/duckdb/duckdb/compare/{base}...{head}https://api.github.com/repos/duckdb/duckdb-web/compare/{base}...{head}https://api.github.com/repos/davidgasquez/awesome-duckdb/compare/{base}...{head}\xE6:E\b"
                                 :contents_url "https://api.github.com/repos/duckdb/duckdb/contents/{+path}https://api.github.com/repos/duckdb/duckdb-web/contents/{+path}https://api.github.com/repos/davidgasquez/awesome-duckdb/contents/{+path}"
                                 :contributors_url "https://api.github.com/repos/duckdb/duckdb/contributorshttps://api.github.com/repos/duckdb/duckdb-web/contributorshttps://api.github.com/repos/davidgasquez/awesome-duckdb/contributors"
                                 :created_at 1530025485000000
                                 :default_branch "main"
                                 :deployments_url "https://api.github.com/repos/duckdb/duckdb/deploymentshttps://api.github.com/repos/duckdb/duckdb-web/deploymentshttps://api.github.com/repos/davidgasquez/awesome-duckdb/deployments"
                                 :description "DuckDB is an analytical in-process SQL database management systemDuckDB website and documentation\xF0\x9F\xA6\x86 A curated list of awesome DuckDB resources"
                                 :disabled false
                                 :downloads_url "https://api.github.com/repos/duckdb/duckdb/downloadshttps://api.github.com/repos/duckdb/duckdb-web/downloadshttps://api.github.com/repos/davidgasquez/awesome-duckdb/downloads"
                                 :events_url "https://api.github.com/repos/duckdb/duckdb/eventshttps://api.github.com/repos/duckdb/duckdb-web/eventshttps://api.github.com/repos/davidgasquez/awesome-duckdb/events"
                                 :fork false
                                 :forks 2422
                                 :forks_count 2422
                                 :forks_url "https://api.github.com/repos/duckdb/duckdb/forkshttps://api.github.com/repos/duckdb/duckdb-web/forkshttps://api.github.com/repos/davidgasquez/awesome-duckdb/forks"
                                 :full_name "duckdb/duckdbduckdb/duckdb-webdavidgasquez/awesome-duckdb"
                                 :git_commits_url "https://api.github.com/repos/duckdb/duckdb/git/commits{/sha}https://api.github.com/repos/duckdb/duckdb-web/git/commits{/sha}https://api.github.com/repos/davidgasquez/awesome-duckdb/git/commits{/sha}"
                                 :git_refs_url "https://api.github.com/repos/duckdb/duckdb/git/refs{/sha}https://api.github.com/repos/duckdb/duckdb-web/git/refs{/sha}https://api.github.com/repos/davidgasquez/awesome-duckdb/git/refs{/sha}"
                                 :git_tags_url "https://api.github.com/repos/duckdb/duckdb/git/tags{/sha}https://api.github.com/repos/duckdb/duckdb-web/git/tags{/sha}https://api.github.com/repos/davidgasquez/awesome-duckdb/git/tags{/sha}"
                                 :git_url "git://github.com/duckdb/duckdb.gitgit://github.com/duckdb/duckdb-web.gitgit://github.com/davidgasquez/awesome-duckdb.git"
                                 :has_discussions true
                                 :has_downloads true
                                 :has_issues true
                                 :has_pages false
                                 :has_projects true
                                 :has_wiki false
                                 :homepage "http://www.duckdb.orghttps://duckdb.orghttps://davidgasquez.github.io/awesome-duckdb/"
                                 :hooks_url "https://api.github.com/repos/duckdb/duckdb/hookshttps://api.github.com/repos/duckdb/duckdb-web/hookshttps://api.github.com/repos/davidgasquez/awesome-duckdb/hooks"
                                 :html_url "https://github.com/duckdb/duckdbhttps://github.com/duckdb/duckdb-webhttps://github.com/davidgasquez/awesome-duckdb"
                                 :id 138754790
                                 :is_template false
                                 :issue_comment_url "https://api.github.com/repos/duckdb/duckdb/issues/comments{/number}https://api.github.com/repos/duckdb/duckdb-web/issues/comments{/number}https://api.github.com/repos/davidgasquez/awesome-duckdb/issues/comments{/number}"
                                 :issue_events_url "https://api.github.com/repos/duckdb/duckdb/issues/events{/number}https://api.github.com/repos/duckdb/duckdb-web/issues/events{/number}https://api.github.com/repos/davidgasquez/awesome-duckdb/issues/events{/number}"
                                 :issues_url "https://api.github.com/repos/duckdb/duckdb/issues{/number}https://api.github.com/repos/duckdb/duckdb-web/issues{/number}https://api.github.com/repos/davidgasquez/awesome-duckdb/issues{/number}"
                                 :keys_url "https://api.github.com/repos/duckdb/duckdb/keys{/key_id}https://api.github.com/repos/duckdb/duckdb-web/keys{/key_id}https://api.github.com/repos/davidgasquez/awesome-duckdb/keys{/key_id}"
                                 :labels_url "https://api.github.com/repos/duckdb/duckdb/labels{/name}https://api.github.com/repos/duckdb/duckdb-web/labels{/name}https://api.github.com/repos/davidgasquez/awesome-duckdb/labels{/name}"
                                 :language "C++"
                                 :languages_url "https://api.github.com/repos/duckdb/duckdb/languageshttps://api.github.com/repos/duckdb/duckdb-web/languageshttps://api.github.com/repos/davidgasquez/awesome-duckdb/languages"
                                 :license {:key "mit"
                                           :name "MIT License"
                                           :node_id "MDc6TGljZW5zZTEzMDc6TGljZW5zZTEzMDc6TGljZW5zZTY="
                                           :spdx_id "MIT"
                                           :url "https://api.github.com/licenses/mithttps://api.github.com/licenses/mithttps://api.github.com/licenses/cc0-1.0"}
                                 :merges_url "https://api.github.com/repos/duckdb/duckdb/mergeshttps://api.github.com/repos/duckdb/duckdb-web/mergeshttps://api.github.com/repos/davidgasquez/awesome-duckdb/merges"
                                 :milestones_url "https://api.github.com/repos/duckdb/duckdb/milestones{/number}https://api.github.com/repos/duckdb/duckdb-web/milestones{/number}https://api.github.com/repos/davidgasquez/awesome-duckdb/milestones{/number}"
                                 :name "duckdb"
                                 :node_id "MDEwOlJlcG9zaXRvcnkxMzg3NTQ3OTA=MDEwOlJlcG9zaXRvcnkxNTUzNzk0ODY="
                                 :notifications_url "https://api.github.com/repos/duckdb/duckdb/notifications{?since,all,participating}https://api.github.com/repos/duckdb/duckdb-web/notifications{?since,all,participating}https://api.github.com/repos/davidgasquez/awesome-duckdb/notifications{?since,all,participating}"
                                 :open_issues 513
                                 :open_issues_count 513
                                 :owner {:avatar_url "https://avatars.githubusercontent.com/u/82039556?v=4https://avatars.githubusercontent.com/u/82039556?v=4https://avatars.githubusercontent.com/u/1682202?v=4"
                                         :events_url "https://api.github.com/users/duckdb/events{/privacy}https://api.github.com/users/duckdb/events{/privacy}https://api.github.com/users/davidgasquez/events{/privacy}"
                                         :followers_url "https://api.github.com/users/duckdb/followershttps://api.github.com/users/duckdb/followershttps://api.github.com/users/davidgasquez/followers"
                                         :following_url "https://api.github.com/users/duckdb/following{/other_user}https://api.github.com/users/duckdb/following{/other_user}https://api.github.com/users/davidgasquez/following{/other_user}"
                                         :gists_url "https://api.github.com/users/duckdb/gists{/gist_id}https://api.github.com/users/duckdb/gists{/gist_id}https://api.github.com/users/davidgasquez/gists{/gist_id}"
                                         :gravatar_id ""
                                         :html_url "https://github.com/duckdbhttps://github.com/duckdbhttps://github.com/davidgasquez"
                                         :id 82039556
                                         :login "duckdb"
                                         :node_id "MDEyOk9yZ2FuaXphdGlvbjgyMDM5NTU2MDEyOk9yZ2FuaXphdGlvbjgyMDM5NTU2MDQ6VXNlcjE2ODIyMDI="
                                         :organizations_url "https://api.github.com/users/duckdb/orgshttps://api.github.com/users/duckdb/orgshttps://api.github.com/users/davidgasquez/orgs"
                                         :received_events_url "https://api.github.com/users/duckdb/received_eventshttps://api.github.com/users/duckdb/received_eventshttps://api.github.com/users/davidgasquez/received_events"
                                         :repos_url "https://api.github.com/users/duckdb/reposhttps://api.github.com/users/duckdb/reposhttps://api.github.com/users/davidgasquez/repos"
                                         :site_admin false
                                         :starred_url "https://api.github.com/users/duckdb/starred{/owner}{/repo}https://api.github.com/users/duckdb/starred{/owner}{/repo}https://api.github.com/users/davidgasquez/starred{/owner}{/repo}"
                                         :subscriptions_url "https://api.github.com/users/duckdb/subscriptionshttps://api.github.com/users/duckdb/subscriptionshttps://api.github.com/users/davidgasquez/subscriptions"
                                         :type "Organization "
                                         :url "https://api.github.com/users/duckdbhttps://api.github.com/users/duckdbhttps://api.github.com/users/davidgasquez"
                                         :user_view_type "public"}
                                 :private false
                                 :pulls_url "https://api.github.com/repos/duckdb/duckdb/pulls{/number}https://api.github.com/repos/duckdb/duckdb-web/pulls{/number}https://api.github.com/repos/davidgasquez/awesome-duckdb/pulls{/number}"
                                 :pushed_at 1751750687000000
                                 :releases_url "https://api.github.com/repos/duckdb/duckdb/releases{/id}https://api.github.com/repos/duckdb/duckdb-web/releases{/id}https://api.github.com/repos/davidgasquez/awesome-duckdb/releases{/id}"
                                 :score 1
                                 :size 354495
                                 :ssh_url "git@github.com:duckdb/duckdb.gitgit@github.com:duckdb/duckdb-web.gitgit@github.com:davidgasquez/awesome-duckdb.git"
                                 :stargazers_count 30765
                                 :stargazers_url "https://api.github.com/repos/duckdb/duckdb/stargazershttps://api.github.com/repos/duckdb/duckdb-web/stargazershttps://api.github.com/repos/davidgasquez/awesome-duckdb/stargazers"
                                 :statuses_url "https://api.github.com/repos/duckdb/duckdb/statuses/{sha}https://api.github.com/repos/duckdb/duckdb-web/statuses/{sha}https://api.github.com/repos/davidgasquez/awesome-duckdb/statuses/{sha}"
                                 :subscribers_url "https://api.github.com/repos/duckdb/duckdb/subscribershttps://api.github.com/repos/duckdb/duckdb-web/subscribershttps://api.github.com/repos/davidgasquez/awesome-duckdb/subscribers"
                                 :subscription_url "https://api.github.com/repos/duckdb/duckdb/subscriptionhttps://api.github.com/repos/duckdb/duckdb-web/subscriptionhttps://api.github.com/repos/davidgasquez/awesome-duckdb/subscription"
                                 :svn_url "https://github.com/duckdb/duckdbhttps://github.com/duckdb/duckdb-webhttps://github.com/davidgasquez/awesome-duckdb"
                                 :tags_url "https://api.github.com/repos/duckdb/duckdb/tagshttps://api.github.com/repos/duckdb/duckdb-web/tagshttps://api.github.com/repos/davidgasquez/awesome-duckdb/tags"
                                 :teams_url "https://api.github.com/repos/duckdb/duckdb/teamshttps://api.github.com/repos/duckdb/duckdb-web/teamshttps://api.github.com/repos/davidgasquez/awesome-duckdb/teams"
                                 :topics @["analytics"
                                           "database"
                                           "embedded-database"
                                           "olap"
                                           "sql"]
                                 :trees_url "https://api.github.com/repos/duckdb/duckdb/git/trees{/sha}https://api.github.com/repos/duckdb/duckdb-web/git/trees{/sha}https://api.github.com/repos/davidgasquez/awesome-duckdb/git/trees{/sha}"
                                 :updated_at 1751837650000000
                                 :url "https://api.github.com/repos/duckdb/duckdbhttps://api.github.com/repos/duckdb/duckdb-webhttps://api.github.com/repos/davidgasquez/awesome-duckdb"
                                 :visibility "public"
                                 :watchers 30765
                                 :watchers_count 30765
                                 :web_commit_signoff_required false}
                                {:allow_forking true
                                 :archive_url "https://api.github.com/repos/duckdb/duckdb-web/{archive_format}{/ref}https://api.github.com/repos/davidgasquez/awesome-duckdb/{archive_format}{/ref}"
                                 :archived false
                                 :assignees_url "https://api.github.com/repos/duckdb/duckdb-web/assignees{/user}https://api.github.com/repos/davidgasquez/awesome-duckdb/assignees{/user}"
                                 :blobs_url "https://api.github.com/repos/duckdb/duckdb-web/git/blobs{/sha}https://api.github.com/repos/davidgasquez/awesome-duckdb/git/blobs{/sha}"
                                 :branches_url "https://api.github.com/repos/duckdb/duckdb-web/branches{/branch}https://api.github.com/repos/davidgasquez/awesome-duckdb/branches{/branch}"
                                 :clone_url "https://github.com/duckdb/duckdb-web.githttps://github.com/davidgasquez/awesome-duckdb.git"
                                 :collaborators_url "https://api.github.com/repos/duckdb/duckdb-web/collaborators{/collaborator}https://api.github.com/repos/davidgasquez/awesome-duckdb/collaborators{/collaborator}"
                                 :comments_url "https://api.github.com/repos/duckdb/duckdb-web/comments{/number}https://api.github.com/repos/davidgasquez/awesome-duckdb/comments{/number}"
                                 :commits_url "https://api.github.com/repos/duckdb/duckdb-web/commits{/sha}https://api.github.com/repos/davidgasquez/awesome-duckdb/commits{/sha}"
                                 :compare_url "https://api.github.com/repos/duckdb/duckdb-web/compare/{base}...{head}https://api.github.com/repos/davidgasquez/awesome-duckdb/compare/{base}...{head}\xE6:E\b"
                                 :contents_url "https://api.github.com/repos/duckdb/duckdb-web/contents/{+path}https://api.github.com/repos/davidgasquez/awesome-duckdb/contents/{+path}"
                                 :contributors_url "https://api.github.com/repos/duckdb/duckdb-web/contributorshttps://api.github.com/repos/davidgasquez/awesome-duckdb/contributors"
                                 :created_at 1540901544000000
                                 :default_branch "main"
                                 :deployments_url "https://api.github.com/repos/duckdb/duckdb-web/deploymentshttps://api.github.com/repos/davidgasquez/awesome-duckdb/deployments"
                                 :description "DuckDB website and documentation\xF0\x9F\xA6\x86 A curated list of awesome DuckDB resources"
                                 :disabled false
                                 :downloads_url "https://api.github.com/repos/duckdb/duckdb-web/downloadshttps://api.github.com/repos/davidgasquez/awesome-duckdb/downloads"
                                 :events_url "https://api.github.com/repos/duckdb/duckdb-web/eventshttps://api.github.com/repos/davidgasquez/awesome-duckdb/events"
                                 :fork false
                                 :forks 430
                                 :forks_count 430
                                 :forks_url "https://api.github.com/repos/duckdb/duckdb-web/forkshttps://api.github.com/repos/davidgasquez/awesome-duckdb/forks"
                                 :full_name "duckdb/duckdb-webdavidgasquez/awesome-duckdb"
                                 :git_commits_url "https://api.github.com/repos/duckdb/duckdb-web/git/commits{/sha}https://api.github.com/repos/davidgasquez/awesome-duckdb/git/commits{/sha}"
                                 :git_refs_url "https://api.github.com/repos/duckdb/duckdb-web/git/refs{/sha}https://api.github.com/repos/davidgasquez/awesome-duckdb/git/refs{/sha}"
                                 :git_tags_url "https://api.github.com/repos/duckdb/duckdb-web/git/tags{/sha}https://api.github.com/repos/davidgasquez/awesome-duckdb/git/tags{/sha}"
                                 :git_url "git://github.com/duckdb/duckdb-web.gitgit://github.com/davidgasquez/awesome-duckdb.git"
                                 :has_discussions false
                                 :has_downloads true
                                 :has_issues true
                                 :has_pages true
                                 :has_projects true
                                 :has_wiki true
                                 :homepage "https://duckdb.orghttps://davidgasquez.github.io/awesome-duckdb/"
                                 :hooks_url "https://api.github.com/repos/duckdb/duckdb-web/hookshttps://api.github.com/repos/davidgasquez/awesome-duckdb/hooks"
                                 :html_url "https://github.com/duckdb/duckdb-webhttps://github.com/davidgasquez/awesome-duckdb"
                                 :id 155379486
                                 :is_template false
                                 :issue_comment_url "https://api.github.com/repos/duckdb/duckdb-web/issues/comments{/number}https://api.github.com/repos/davidgasquez/awesome-duckdb/issues/comments{/number}"
                                 :issue_events_url "https://api.github.com/repos/duckdb/duckdb-web/issues/events{/number}https://api.github.com/repos/davidgasquez/awesome-duckdb/issues/events{/number}"
                                 :issues_url "https://api.github.com/repos/duckdb/duckdb-web/issues{/number}https://api.github.com/repos/davidgasquez/awesome-duckdb/issues{/number}"
                                 :keys_url "https://api.github.com/repos/duckdb/duckdb-web/keys{/key_id}https://api.github.com/repos/davidgasquez/awesome-duckdb/keys{/key_id}"
                                 :labels_url "https://api.github.com/repos/duckdb/duckdb-web/labels{/name}https://api.github.com/repos/davidgasquez/awesome-duckdb/labels{/name}"
                                 :language "JavaScript"
                                 :languages_url "https://api.github.com/repos/duckdb/duckdb-web/languageshttps://api.github.com/repos/davidgasquez/awesome-duckdb/languages"
                                 :license {:key "mit"
                                           :name "MIT License"
                                           :node_id "MDc6TGljZW5zZTEzMDc6TGljZW5zZTY="
                                           :spdx_id "MIT"
                                           :url "https://api.github.com/licenses/mithttps://api.github.com/licenses/cc0-1.0"}
                                 :merges_url "https://api.github.com/repos/duckdb/duckdb-web/mergeshttps://api.github.com/repos/davidgasquez/awesome-duckdb/merges"
                                 :milestones_url "https://api.github.com/repos/duckdb/duckdb-web/milestones{/number}https://api.github.com/repos/davidgasquez/awesome-duckdb/milestones{/number}"
                                 :name "duckdb-web"
                                 :node_id "MDEwOlJlcG9zaXRvcnkxNTUzNzk0ODY="
                                 :notifications_url "https://api.github.com/repos/duckdb/duckdb-web/notifications{?since,all,participating}https://api.github.com/repos/davidgasquez/awesome-duckdb/notifications{?since,all,participating}"
                                 :open_issues 115
                                 :open_issues_count 115
                                 :owner {:avatar_url "https://avatars.githubusercontent.com/u/82039556?v=4https://avatars.githubusercontent.com/u/1682202?v=4"
                                         :events_url "https://api.github.com/users/duckdb/events{/privacy}https://api.github.com/users/davidgasquez/events{/privacy}"
                                         :followers_url "https://api.github.com/users/duckdb/followershttps://api.github.com/users/davidgasquez/followers"
                                         :following_url "https://api.github.com/users/duckdb/following{/other_user}https://api.github.com/users/davidgasquez/following{/other_user}"
                                         :gists_url "https://api.github.com/users/duckdb/gists{/gist_id}https://api.github.com/users/davidgasquez/gists{/gist_id}"
                                         :gravatar_id ""
                                         :html_url "https://github.com/duckdbhttps://github.com/davidgasquez"
                                         :id 82039556
                                         :login "duckdb"
                                         :node_id "MDEyOk9yZ2FuaXphdGlvbjgyMDM5NTU2MDQ6VXNlcjE2ODIyMDI="
                                         :organizations_url "https://api.github.com/users/duckdb/orgshttps://api.github.com/users/davidgasquez/orgs"
                                         :received_events_url "https://api.github.com/users/duckdb/received_eventshttps://api.github.com/users/davidgasquez/received_events"
                                         :repos_url "https://api.github.com/users/duckdb/reposhttps://api.github.com/users/davidgasquez/repos"
                                         :site_admin false
                                         :starred_url "https://api.github.com/users/duckdb/starred{/owner}{/repo}https://api.github.com/users/davidgasquez/starred{/owner}{/repo}"
                                         :subscriptions_url "https://api.github.com/users/duckdb/subscriptionshttps://api.github.com/users/davidgasquez/subscriptions"
                                         :type "Organization "
                                         :url "https://api.github.com/users/duckdbhttps://api.github.com/users/davidgasquez"
                                         :user_view_type "public"}
                                 :private false
                                 :pulls_url "https://api.github.com/repos/duckdb/duckdb-web/pulls{/number}https://api.github.com/repos/davidgasquez/awesome-duckdb/pulls{/number}"
                                 :pushed_at 1751825198000000
                                 :releases_url "https://api.github.com/repos/duckdb/duckdb-web/releases{/id}https://api.github.com/repos/davidgasquez/awesome-duckdb/releases{/id}"
                                 :score 1
                                 :size 206076
                                 :ssh_url "git@github.com:duckdb/duckdb-web.gitgit@github.com:davidgasquez/awesome-duckdb.git"
                                 :stargazers_count 231
                                 :stargazers_url "https://api.github.com/repos/duckdb/duckdb-web/stargazershttps://api.github.com/repos/davidgasquez/awesome-duckdb/stargazers"
                                 :statuses_url "https://api.github.com/repos/duckdb/duckdb-web/statuses/{sha}https://api.github.com/repos/davidgasquez/awesome-duckdb/statuses/{sha}"
                                 :subscribers_url "https://api.github.com/repos/duckdb/duckdb-web/subscribershttps://api.github.com/repos/davidgasquez/awesome-duckdb/subscribers"
                                 :subscription_url "https://api.github.com/repos/duckdb/duckdb-web/subscriptionhttps://api.github.com/repos/davidgasquez/awesome-duckdb/subscription"
                                 :svn_url "https://github.com/duckdb/duckdb-webhttps://github.com/davidgasquez/awesome-duckdb"
                                 :tags_url "https://api.github.com/repos/duckdb/duckdb-web/tagshttps://api.github.com/repos/davidgasquez/awesome-duckdb/tags"
                                 :teams_url "https://api.github.com/repos/duckdb/duckdb-web/teamshttps://api.github.com/repos/davidgasquez/awesome-duckdb/teams"
                                 :topics @[]
                                 :trees_url "https://api.github.com/repos/duckdb/duckdb-web/git/trees{/sha}https://api.github.com/repos/davidgasquez/awesome-duckdb/git/trees{/sha}"
                                 :updated_at 1751640447000000
                                 :url "https://api.github.com/repos/duckdb/duckdb-webhttps://api.github.com/repos/davidgasquez/awesome-duckdb"
                                 :visibility "public"
                                 :watchers 231
                                 :watchers_count 231
                                 :web_commit_signoff_required false}
                                {:allow_forking true
                                 :archive_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/{archive_format}{/ref}"
                                 :archived false
                                 :assignees_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/assignees{/user}"
                                 :blobs_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/git/blobs{/sha}"
                                 :branches_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/branches{/branch}"
                                 :clone_url "https://github.com/davidgasquez/awesome-duckdb.git"
                                 :collaborators_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/collaborators{/collaborator}"
                                 :comments_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/comments{/number}"
                                 :commits_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/commits{/sha}"
                                 :compare_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/compare/{base}...{head}\xE6:E\b"
                                 :contents_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/contents/{+path}"
                                 :contributors_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/contributors"
                                 :created_at 1673724612000000
                                 :default_branch "main"
                                 :deployments_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/deployments"
                                 :description "\xF0\x9F\xA6\x86 A curated list of awesome DuckDB resources"
                                 :disabled false
                                 :downloads_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/downloads"
                                 :events_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/events"
                                 :fork false
                                 :forks 145
                                 :forks_count 145
                                 :forks_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/forks"
                                 :full_name "davidgasquez/awesome-duckdb"
                                 :git_commits_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/git/commits{/sha}"
                                 :git_refs_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/git/refs{/sha}"
                                 :git_tags_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/git/tags{/sha}"
                                 :git_url "git://github.com/davidgasquez/awesome-duckdb.git"
                                 :has_discussions false
                                 :has_downloads true
                                 :has_issues true
                                 :has_pages true
                                 :has_projects true
                                 :has_wiki false
                                 :homepage "https://davidgasquez.github.io/awesome-duckdb/"
                                 :hooks_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/hooks"
                                 :html_url "https://github.com/davidgasquez/awesome-duckdb"
                                 :id 589014131
                                 :is_template false
                                 :issue_comment_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/issues/comments{/number}"
                                 :issue_events_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/issues/events{/number}"
                                 :issues_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/issues{/number}"
                                 :keys_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/keys{/key_id}"
                                 :labels_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/labels{/name}"
                                 :languages_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/languages"
                                 :license {:key "cc0-1.0"
                                           :name "Creative Commons Zero v1.0 Universal"
                                           :node_id "MDc6TGljZW5zZTY="
                                           :spdx_id "CC0-1.0"
                                           :url "https://api.github.com/licenses/cc0-1.0"}
                                 :merges_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/merges"
                                 :milestones_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/milestones{/number}"
                                 :name "awesome-duckdb"
                                 :node_id "R_kgDOIxukcw "
                                 :notifications_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/notifications{?since,all,participating}"
                                 :open_issues 1
                                 :open_issues_count 1
                                 :owner {:avatar_url "https://avatars.githubusercontent.com/u/1682202?v=4"
                                         :events_url "https://api.github.com/users/davidgasquez/events{/privacy}"
                                         :followers_url "https://api.github.com/users/davidgasquez/followers"
                                         :following_url "https://api.github.com/users/davidgasquez/following{/other_user}"
                                         :gists_url "https://api.github.com/users/davidgasquez/gists{/gist_id}"
                                         :gravatar_id ""
                                         :html_url "https://github.com/davidgasquez"
                                         :id 1682202
                                         :login "davidgasquez "
                                         :node_id "MDQ6VXNlcjE2ODIyMDI="
                                         :organizations_url "https://api.github.com/users/davidgasquez/orgs"
                                         :received_events_url "https://api.github.com/users/davidgasquez/received_events"
                                         :repos_url "https://api.github.com/users/davidgasquez/repos"
                                         :site_admin false
                                         :starred_url "https://api.github.com/users/davidgasquez/starred{/owner}{/repo}"
                                         :subscriptions_url "https://api.github.com/users/davidgasquez/subscriptions"
                                         :type "User"
                                         :url "https://api.github.com/users/davidgasquez"
                                         :user_view_type "public"}
                                 :private false
                                 :pulls_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/pulls{/number}"
                                 :pushed_at 1751618165000000
                                 :releases_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/releases{/id}"
                                 :score 1
                                 :size 468
                                 :ssh_url "git@github.com:davidgasquez/awesome-duckdb.git"
                                 :stargazers_count 1910
                                 :stargazers_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/stargazers"
                                 :statuses_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/statuses/{sha}"
                                 :subscribers_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/subscribers"
                                 :subscription_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/subscription"
                                 :svn_url "https://github.com/davidgasquez/awesome-duckdb"
                                 :tags_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/tags"
                                 :teams_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/teams"
                                 :topics @["awesome" "awesome-list\x90"]
                                 :trees_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/git/trees{/sha}"
                                 :updated_at 1751837059000000
                                 :url "https://api.github.com/repos/davidgasquez/awesome-duckdb"
                                 :visibility "public"
                                 :watchers 1910
                                 :watchers_count 1910
                                 :web_commit_signoff_required false}]]]
                 :row-count 1})

          (test (result/columns-to-rows columns)
                @[{:incomplete_results false
                   :items @[{:allow_forking true
                             :archive_url "https://api.github.com/repos/duckdb/duckdb/{archive_format}{/ref}https://api.github.com/repos/duckdb/duckdb-web/{archive_format}{/ref}https://api.github.com/repos/davidgasquez/awesome-duckdb/{archive_format}{/ref}"
                             :archived false
                             :assignees_url "https://api.github.com/repos/duckdb/duckdb/assignees{/user}https://api.github.com/repos/duckdb/duckdb-web/assignees{/user}https://api.github.com/repos/davidgasquez/awesome-duckdb/assignees{/user}"
                             :blobs_url "https://api.github.com/repos/duckdb/duckdb/git/blobs{/sha}https://api.github.com/repos/duckdb/duckdb-web/git/blobs{/sha}https://api.github.com/repos/davidgasquez/awesome-duckdb/git/blobs{/sha}"
                             :branches_url "https://api.github.com/repos/duckdb/duckdb/branches{/branch}https://api.github.com/repos/duckdb/duckdb-web/branches{/branch}https://api.github.com/repos/davidgasquez/awesome-duckdb/branches{/branch}"
                             :clone_url "https://github.com/duckdb/duckdb.githttps://github.com/duckdb/duckdb-web.githttps://github.com/davidgasquez/awesome-duckdb.git"
                             :collaborators_url "https://api.github.com/repos/duckdb/duckdb/collaborators{/collaborator}https://api.github.com/repos/duckdb/duckdb-web/collaborators{/collaborator}https://api.github.com/repos/davidgasquez/awesome-duckdb/collaborators{/collaborator}"
                             :comments_url "https://api.github.com/repos/duckdb/duckdb/comments{/number}https://api.github.com/repos/duckdb/duckdb-web/comments{/number}https://api.github.com/repos/davidgasquez/awesome-duckdb/comments{/number}"
                             :commits_url "https://api.github.com/repos/duckdb/duckdb/commits{/sha}https://api.github.com/repos/duckdb/duckdb-web/commits{/sha}https://api.github.com/repos/davidgasquez/awesome-duckdb/commits{/sha}"
                             :compare_url "https://api.github.com/repos/duckdb/duckdb/compare/{base}...{head}https://api.github.com/repos/duckdb/duckdb-web/compare/{base}...{head}https://api.github.com/repos/davidgasquez/awesome-duckdb/compare/{base}...{head}\xE6:E\b"
                             :contents_url "https://api.github.com/repos/duckdb/duckdb/contents/{+path}https://api.github.com/repos/duckdb/duckdb-web/contents/{+path}https://api.github.com/repos/davidgasquez/awesome-duckdb/contents/{+path}"
                             :contributors_url "https://api.github.com/repos/duckdb/duckdb/contributorshttps://api.github.com/repos/duckdb/duckdb-web/contributorshttps://api.github.com/repos/davidgasquez/awesome-duckdb/contributors"
                             :created_at 1530025485000000
                             :default_branch "main"
                             :deployments_url "https://api.github.com/repos/duckdb/duckdb/deploymentshttps://api.github.com/repos/duckdb/duckdb-web/deploymentshttps://api.github.com/repos/davidgasquez/awesome-duckdb/deployments"
                             :description "DuckDB is an analytical in-process SQL database management systemDuckDB website and documentation\xF0\x9F\xA6\x86 A curated list of awesome DuckDB resources"
                             :disabled false
                             :downloads_url "https://api.github.com/repos/duckdb/duckdb/downloadshttps://api.github.com/repos/duckdb/duckdb-web/downloadshttps://api.github.com/repos/davidgasquez/awesome-duckdb/downloads"
                             :events_url "https://api.github.com/repos/duckdb/duckdb/eventshttps://api.github.com/repos/duckdb/duckdb-web/eventshttps://api.github.com/repos/davidgasquez/awesome-duckdb/events"
                             :fork false
                             :forks 2422
                             :forks_count 2422
                             :forks_url "https://api.github.com/repos/duckdb/duckdb/forkshttps://api.github.com/repos/duckdb/duckdb-web/forkshttps://api.github.com/repos/davidgasquez/awesome-duckdb/forks"
                             :full_name "duckdb/duckdbduckdb/duckdb-webdavidgasquez/awesome-duckdb"
                             :git_commits_url "https://api.github.com/repos/duckdb/duckdb/git/commits{/sha}https://api.github.com/repos/duckdb/duckdb-web/git/commits{/sha}https://api.github.com/repos/davidgasquez/awesome-duckdb/git/commits{/sha}"
                             :git_refs_url "https://api.github.com/repos/duckdb/duckdb/git/refs{/sha}https://api.github.com/repos/duckdb/duckdb-web/git/refs{/sha}https://api.github.com/repos/davidgasquez/awesome-duckdb/git/refs{/sha}"
                             :git_tags_url "https://api.github.com/repos/duckdb/duckdb/git/tags{/sha}https://api.github.com/repos/duckdb/duckdb-web/git/tags{/sha}https://api.github.com/repos/davidgasquez/awesome-duckdb/git/tags{/sha}"
                             :git_url "git://github.com/duckdb/duckdb.gitgit://github.com/duckdb/duckdb-web.gitgit://github.com/davidgasquez/awesome-duckdb.git"
                             :has_discussions true
                             :has_downloads true
                             :has_issues true
                             :has_pages false
                             :has_projects true
                             :has_wiki false
                             :homepage "http://www.duckdb.orghttps://duckdb.orghttps://davidgasquez.github.io/awesome-duckdb/"
                             :hooks_url "https://api.github.com/repos/duckdb/duckdb/hookshttps://api.github.com/repos/duckdb/duckdb-web/hookshttps://api.github.com/repos/davidgasquez/awesome-duckdb/hooks"
                             :html_url "https://github.com/duckdb/duckdbhttps://github.com/duckdb/duckdb-webhttps://github.com/davidgasquez/awesome-duckdb"
                             :id 138754790
                             :is_template false
                             :issue_comment_url "https://api.github.com/repos/duckdb/duckdb/issues/comments{/number}https://api.github.com/repos/duckdb/duckdb-web/issues/comments{/number}https://api.github.com/repos/davidgasquez/awesome-duckdb/issues/comments{/number}"
                             :issue_events_url "https://api.github.com/repos/duckdb/duckdb/issues/events{/number}https://api.github.com/repos/duckdb/duckdb-web/issues/events{/number}https://api.github.com/repos/davidgasquez/awesome-duckdb/issues/events{/number}"
                             :issues_url "https://api.github.com/repos/duckdb/duckdb/issues{/number}https://api.github.com/repos/duckdb/duckdb-web/issues{/number}https://api.github.com/repos/davidgasquez/awesome-duckdb/issues{/number}"
                             :keys_url "https://api.github.com/repos/duckdb/duckdb/keys{/key_id}https://api.github.com/repos/duckdb/duckdb-web/keys{/key_id}https://api.github.com/repos/davidgasquez/awesome-duckdb/keys{/key_id}"
                             :labels_url "https://api.github.com/repos/duckdb/duckdb/labels{/name}https://api.github.com/repos/duckdb/duckdb-web/labels{/name}https://api.github.com/repos/davidgasquez/awesome-duckdb/labels{/name}"
                             :language "C++"
                             :languages_url "https://api.github.com/repos/duckdb/duckdb/languageshttps://api.github.com/repos/duckdb/duckdb-web/languageshttps://api.github.com/repos/davidgasquez/awesome-duckdb/languages"
                             :license {:key "mit"
                                       :name "MIT License"
                                       :node_id "MDc6TGljZW5zZTEzMDc6TGljZW5zZTEzMDc6TGljZW5zZTY="
                                       :spdx_id "MIT"
                                       :url "https://api.github.com/licenses/mithttps://api.github.com/licenses/mithttps://api.github.com/licenses/cc0-1.0"}
                             :merges_url "https://api.github.com/repos/duckdb/duckdb/mergeshttps://api.github.com/repos/duckdb/duckdb-web/mergeshttps://api.github.com/repos/davidgasquez/awesome-duckdb/merges"
                             :milestones_url "https://api.github.com/repos/duckdb/duckdb/milestones{/number}https://api.github.com/repos/duckdb/duckdb-web/milestones{/number}https://api.github.com/repos/davidgasquez/awesome-duckdb/milestones{/number}"
                             :name "duckdb"
                             :node_id "MDEwOlJlcG9zaXRvcnkxMzg3NTQ3OTA=MDEwOlJlcG9zaXRvcnkxNTUzNzk0ODY="
                             :notifications_url "https://api.github.com/repos/duckdb/duckdb/notifications{?since,all,participating}https://api.github.com/repos/duckdb/duckdb-web/notifications{?since,all,participating}https://api.github.com/repos/davidgasquez/awesome-duckdb/notifications{?since,all,participating}"
                             :open_issues 513
                             :open_issues_count 513
                             :owner {:avatar_url "https://avatars.githubusercontent.com/u/82039556?v=4https://avatars.githubusercontent.com/u/82039556?v=4https://avatars.githubusercontent.com/u/1682202?v=4"
                                     :events_url "https://api.github.com/users/duckdb/events{/privacy}https://api.github.com/users/duckdb/events{/privacy}https://api.github.com/users/davidgasquez/events{/privacy}"
                                     :followers_url "https://api.github.com/users/duckdb/followershttps://api.github.com/users/duckdb/followershttps://api.github.com/users/davidgasquez/followers"
                                     :following_url "https://api.github.com/users/duckdb/following{/other_user}https://api.github.com/users/duckdb/following{/other_user}https://api.github.com/users/davidgasquez/following{/other_user}"
                                     :gists_url "https://api.github.com/users/duckdb/gists{/gist_id}https://api.github.com/users/duckdb/gists{/gist_id}https://api.github.com/users/davidgasquez/gists{/gist_id}"
                                     :gravatar_id ""
                                     :html_url "https://github.com/duckdbhttps://github.com/duckdbhttps://github.com/davidgasquez"
                                     :id 82039556
                                     :login "duckdb"
                                     :node_id "MDEyOk9yZ2FuaXphdGlvbjgyMDM5NTU2MDEyOk9yZ2FuaXphdGlvbjgyMDM5NTU2MDQ6VXNlcjE2ODIyMDI="
                                     :organizations_url "https://api.github.com/users/duckdb/orgshttps://api.github.com/users/duckdb/orgshttps://api.github.com/users/davidgasquez/orgs"
                                     :received_events_url "https://api.github.com/users/duckdb/received_eventshttps://api.github.com/users/duckdb/received_eventshttps://api.github.com/users/davidgasquez/received_events"
                                     :repos_url "https://api.github.com/users/duckdb/reposhttps://api.github.com/users/duckdb/reposhttps://api.github.com/users/davidgasquez/repos"
                                     :site_admin false
                                     :starred_url "https://api.github.com/users/duckdb/starred{/owner}{/repo}https://api.github.com/users/duckdb/starred{/owner}{/repo}https://api.github.com/users/davidgasquez/starred{/owner}{/repo}"
                                     :subscriptions_url "https://api.github.com/users/duckdb/subscriptionshttps://api.github.com/users/duckdb/subscriptionshttps://api.github.com/users/davidgasquez/subscriptions"
                                     :type "Organization "
                                     :url "https://api.github.com/users/duckdbhttps://api.github.com/users/duckdbhttps://api.github.com/users/davidgasquez"
                                     :user_view_type "public"}
                             :private false
                             :pulls_url "https://api.github.com/repos/duckdb/duckdb/pulls{/number}https://api.github.com/repos/duckdb/duckdb-web/pulls{/number}https://api.github.com/repos/davidgasquez/awesome-duckdb/pulls{/number}"
                             :pushed_at 1751750687000000
                             :releases_url "https://api.github.com/repos/duckdb/duckdb/releases{/id}https://api.github.com/repos/duckdb/duckdb-web/releases{/id}https://api.github.com/repos/davidgasquez/awesome-duckdb/releases{/id}"
                             :score 1
                             :size 354495
                             :ssh_url "git@github.com:duckdb/duckdb.gitgit@github.com:duckdb/duckdb-web.gitgit@github.com:davidgasquez/awesome-duckdb.git"
                             :stargazers_count 30765
                             :stargazers_url "https://api.github.com/repos/duckdb/duckdb/stargazershttps://api.github.com/repos/duckdb/duckdb-web/stargazershttps://api.github.com/repos/davidgasquez/awesome-duckdb/stargazers"
                             :statuses_url "https://api.github.com/repos/duckdb/duckdb/statuses/{sha}https://api.github.com/repos/duckdb/duckdb-web/statuses/{sha}https://api.github.com/repos/davidgasquez/awesome-duckdb/statuses/{sha}"
                             :subscribers_url "https://api.github.com/repos/duckdb/duckdb/subscribershttps://api.github.com/repos/duckdb/duckdb-web/subscribershttps://api.github.com/repos/davidgasquez/awesome-duckdb/subscribers"
                             :subscription_url "https://api.github.com/repos/duckdb/duckdb/subscriptionhttps://api.github.com/repos/duckdb/duckdb-web/subscriptionhttps://api.github.com/repos/davidgasquez/awesome-duckdb/subscription"
                             :svn_url "https://github.com/duckdb/duckdbhttps://github.com/duckdb/duckdb-webhttps://github.com/davidgasquez/awesome-duckdb"
                             :tags_url "https://api.github.com/repos/duckdb/duckdb/tagshttps://api.github.com/repos/duckdb/duckdb-web/tagshttps://api.github.com/repos/davidgasquez/awesome-duckdb/tags"
                             :teams_url "https://api.github.com/repos/duckdb/duckdb/teamshttps://api.github.com/repos/duckdb/duckdb-web/teamshttps://api.github.com/repos/davidgasquez/awesome-duckdb/teams"
                             :topics @["analytics"
                                       "database"
                                       "embedded-database"
                                       "olap"
                                       "sql"]
                             :trees_url "https://api.github.com/repos/duckdb/duckdb/git/trees{/sha}https://api.github.com/repos/duckdb/duckdb-web/git/trees{/sha}https://api.github.com/repos/davidgasquez/awesome-duckdb/git/trees{/sha}"
                             :updated_at 1751837650000000
                             :url "https://api.github.com/repos/duckdb/duckdbhttps://api.github.com/repos/duckdb/duckdb-webhttps://api.github.com/repos/davidgasquez/awesome-duckdb"
                             :visibility "public"
                             :watchers 30765
                             :watchers_count 30765
                             :web_commit_signoff_required false}
                            {:allow_forking true
                             :archive_url "https://api.github.com/repos/duckdb/duckdb-web/{archive_format}{/ref}https://api.github.com/repos/davidgasquez/awesome-duckdb/{archive_format}{/ref}"
                             :archived false
                             :assignees_url "https://api.github.com/repos/duckdb/duckdb-web/assignees{/user}https://api.github.com/repos/davidgasquez/awesome-duckdb/assignees{/user}"
                             :blobs_url "https://api.github.com/repos/duckdb/duckdb-web/git/blobs{/sha}https://api.github.com/repos/davidgasquez/awesome-duckdb/git/blobs{/sha}"
                             :branches_url "https://api.github.com/repos/duckdb/duckdb-web/branches{/branch}https://api.github.com/repos/davidgasquez/awesome-duckdb/branches{/branch}"
                             :clone_url "https://github.com/duckdb/duckdb-web.githttps://github.com/davidgasquez/awesome-duckdb.git"
                             :collaborators_url "https://api.github.com/repos/duckdb/duckdb-web/collaborators{/collaborator}https://api.github.com/repos/davidgasquez/awesome-duckdb/collaborators{/collaborator}"
                             :comments_url "https://api.github.com/repos/duckdb/duckdb-web/comments{/number}https://api.github.com/repos/davidgasquez/awesome-duckdb/comments{/number}"
                             :commits_url "https://api.github.com/repos/duckdb/duckdb-web/commits{/sha}https://api.github.com/repos/davidgasquez/awesome-duckdb/commits{/sha}"
                             :compare_url "https://api.github.com/repos/duckdb/duckdb-web/compare/{base}...{head}https://api.github.com/repos/davidgasquez/awesome-duckdb/compare/{base}...{head}\xE6:E\b"
                             :contents_url "https://api.github.com/repos/duckdb/duckdb-web/contents/{+path}https://api.github.com/repos/davidgasquez/awesome-duckdb/contents/{+path}"
                             :contributors_url "https://api.github.com/repos/duckdb/duckdb-web/contributorshttps://api.github.com/repos/davidgasquez/awesome-duckdb/contributors"
                             :created_at 1540901544000000
                             :default_branch "main"
                             :deployments_url "https://api.github.com/repos/duckdb/duckdb-web/deploymentshttps://api.github.com/repos/davidgasquez/awesome-duckdb/deployments"
                             :description "DuckDB website and documentation\xF0\x9F\xA6\x86 A curated list of awesome DuckDB resources"
                             :disabled false
                             :downloads_url "https://api.github.com/repos/duckdb/duckdb-web/downloadshttps://api.github.com/repos/davidgasquez/awesome-duckdb/downloads"
                             :events_url "https://api.github.com/repos/duckdb/duckdb-web/eventshttps://api.github.com/repos/davidgasquez/awesome-duckdb/events"
                             :fork false
                             :forks 430
                             :forks_count 430
                             :forks_url "https://api.github.com/repos/duckdb/duckdb-web/forkshttps://api.github.com/repos/davidgasquez/awesome-duckdb/forks"
                             :full_name "duckdb/duckdb-webdavidgasquez/awesome-duckdb"
                             :git_commits_url "https://api.github.com/repos/duckdb/duckdb-web/git/commits{/sha}https://api.github.com/repos/davidgasquez/awesome-duckdb/git/commits{/sha}"
                             :git_refs_url "https://api.github.com/repos/duckdb/duckdb-web/git/refs{/sha}https://api.github.com/repos/davidgasquez/awesome-duckdb/git/refs{/sha}"
                             :git_tags_url "https://api.github.com/repos/duckdb/duckdb-web/git/tags{/sha}https://api.github.com/repos/davidgasquez/awesome-duckdb/git/tags{/sha}"
                             :git_url "git://github.com/duckdb/duckdb-web.gitgit://github.com/davidgasquez/awesome-duckdb.git"
                             :has_discussions false
                             :has_downloads true
                             :has_issues true
                             :has_pages true
                             :has_projects true
                             :has_wiki true
                             :homepage "https://duckdb.orghttps://davidgasquez.github.io/awesome-duckdb/"
                             :hooks_url "https://api.github.com/repos/duckdb/duckdb-web/hookshttps://api.github.com/repos/davidgasquez/awesome-duckdb/hooks"
                             :html_url "https://github.com/duckdb/duckdb-webhttps://github.com/davidgasquez/awesome-duckdb"
                             :id 155379486
                             :is_template false
                             :issue_comment_url "https://api.github.com/repos/duckdb/duckdb-web/issues/comments{/number}https://api.github.com/repos/davidgasquez/awesome-duckdb/issues/comments{/number}"
                             :issue_events_url "https://api.github.com/repos/duckdb/duckdb-web/issues/events{/number}https://api.github.com/repos/davidgasquez/awesome-duckdb/issues/events{/number}"
                             :issues_url "https://api.github.com/repos/duckdb/duckdb-web/issues{/number}https://api.github.com/repos/davidgasquez/awesome-duckdb/issues{/number}"
                             :keys_url "https://api.github.com/repos/duckdb/duckdb-web/keys{/key_id}https://api.github.com/repos/davidgasquez/awesome-duckdb/keys{/key_id}"
                             :labels_url "https://api.github.com/repos/duckdb/duckdb-web/labels{/name}https://api.github.com/repos/davidgasquez/awesome-duckdb/labels{/name}"
                             :language "JavaScript"
                             :languages_url "https://api.github.com/repos/duckdb/duckdb-web/languageshttps://api.github.com/repos/davidgasquez/awesome-duckdb/languages"
                             :license {:key "mit"
                                       :name "MIT License"
                                       :node_id "MDc6TGljZW5zZTEzMDc6TGljZW5zZTY="
                                       :spdx_id "MIT"
                                       :url "https://api.github.com/licenses/mithttps://api.github.com/licenses/cc0-1.0"}
                             :merges_url "https://api.github.com/repos/duckdb/duckdb-web/mergeshttps://api.github.com/repos/davidgasquez/awesome-duckdb/merges"
                             :milestones_url "https://api.github.com/repos/duckdb/duckdb-web/milestones{/number}https://api.github.com/repos/davidgasquez/awesome-duckdb/milestones{/number}"
                             :name "duckdb-web"
                             :node_id "MDEwOlJlcG9zaXRvcnkxNTUzNzk0ODY="
                             :notifications_url "https://api.github.com/repos/duckdb/duckdb-web/notifications{?since,all,participating}https://api.github.com/repos/davidgasquez/awesome-duckdb/notifications{?since,all,participating}"
                             :open_issues 115
                             :open_issues_count 115
                             :owner {:avatar_url "https://avatars.githubusercontent.com/u/82039556?v=4https://avatars.githubusercontent.com/u/1682202?v=4"
                                     :events_url "https://api.github.com/users/duckdb/events{/privacy}https://api.github.com/users/davidgasquez/events{/privacy}"
                                     :followers_url "https://api.github.com/users/duckdb/followershttps://api.github.com/users/davidgasquez/followers"
                                     :following_url "https://api.github.com/users/duckdb/following{/other_user}https://api.github.com/users/davidgasquez/following{/other_user}"
                                     :gists_url "https://api.github.com/users/duckdb/gists{/gist_id}https://api.github.com/users/davidgasquez/gists{/gist_id}"
                                     :gravatar_id ""
                                     :html_url "https://github.com/duckdbhttps://github.com/davidgasquez"
                                     :id 82039556
                                     :login "duckdb"
                                     :node_id "MDEyOk9yZ2FuaXphdGlvbjgyMDM5NTU2MDQ6VXNlcjE2ODIyMDI="
                                     :organizations_url "https://api.github.com/users/duckdb/orgshttps://api.github.com/users/davidgasquez/orgs"
                                     :received_events_url "https://api.github.com/users/duckdb/received_eventshttps://api.github.com/users/davidgasquez/received_events"
                                     :repos_url "https://api.github.com/users/duckdb/reposhttps://api.github.com/users/davidgasquez/repos"
                                     :site_admin false
                                     :starred_url "https://api.github.com/users/duckdb/starred{/owner}{/repo}https://api.github.com/users/davidgasquez/starred{/owner}{/repo}"
                                     :subscriptions_url "https://api.github.com/users/duckdb/subscriptionshttps://api.github.com/users/davidgasquez/subscriptions"
                                     :type "Organization "
                                     :url "https://api.github.com/users/duckdbhttps://api.github.com/users/davidgasquez"
                                     :user_view_type "public"}
                             :private false
                             :pulls_url "https://api.github.com/repos/duckdb/duckdb-web/pulls{/number}https://api.github.com/repos/davidgasquez/awesome-duckdb/pulls{/number}"
                             :pushed_at 1751825198000000
                             :releases_url "https://api.github.com/repos/duckdb/duckdb-web/releases{/id}https://api.github.com/repos/davidgasquez/awesome-duckdb/releases{/id}"
                             :score 1
                             :size 206076
                             :ssh_url "git@github.com:duckdb/duckdb-web.gitgit@github.com:davidgasquez/awesome-duckdb.git"
                             :stargazers_count 231
                             :stargazers_url "https://api.github.com/repos/duckdb/duckdb-web/stargazershttps://api.github.com/repos/davidgasquez/awesome-duckdb/stargazers"
                             :statuses_url "https://api.github.com/repos/duckdb/duckdb-web/statuses/{sha}https://api.github.com/repos/davidgasquez/awesome-duckdb/statuses/{sha}"
                             :subscribers_url "https://api.github.com/repos/duckdb/duckdb-web/subscribershttps://api.github.com/repos/davidgasquez/awesome-duckdb/subscribers"
                             :subscription_url "https://api.github.com/repos/duckdb/duckdb-web/subscriptionhttps://api.github.com/repos/davidgasquez/awesome-duckdb/subscription"
                             :svn_url "https://github.com/duckdb/duckdb-webhttps://github.com/davidgasquez/awesome-duckdb"
                             :tags_url "https://api.github.com/repos/duckdb/duckdb-web/tagshttps://api.github.com/repos/davidgasquez/awesome-duckdb/tags"
                             :teams_url "https://api.github.com/repos/duckdb/duckdb-web/teamshttps://api.github.com/repos/davidgasquez/awesome-duckdb/teams"
                             :topics @[]
                             :trees_url "https://api.github.com/repos/duckdb/duckdb-web/git/trees{/sha}https://api.github.com/repos/davidgasquez/awesome-duckdb/git/trees{/sha}"
                             :updated_at 1751640447000000
                             :url "https://api.github.com/repos/duckdb/duckdb-webhttps://api.github.com/repos/davidgasquez/awesome-duckdb"
                             :visibility "public"
                             :watchers 231
                             :watchers_count 231
                             :web_commit_signoff_required false}
                            {:allow_forking true
                             :archive_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/{archive_format}{/ref}"
                             :archived false
                             :assignees_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/assignees{/user}"
                             :blobs_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/git/blobs{/sha}"
                             :branches_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/branches{/branch}"
                             :clone_url "https://github.com/davidgasquez/awesome-duckdb.git"
                             :collaborators_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/collaborators{/collaborator}"
                             :comments_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/comments{/number}"
                             :commits_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/commits{/sha}"
                             :compare_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/compare/{base}...{head}\xE6:E\b"
                             :contents_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/contents/{+path}"
                             :contributors_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/contributors"
                             :created_at 1673724612000000
                             :default_branch "main"
                             :deployments_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/deployments"
                             :description "\xF0\x9F\xA6\x86 A curated list of awesome DuckDB resources"
                             :disabled false
                             :downloads_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/downloads"
                             :events_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/events"
                             :fork false
                             :forks 145
                             :forks_count 145
                             :forks_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/forks"
                             :full_name "davidgasquez/awesome-duckdb"
                             :git_commits_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/git/commits{/sha}"
                             :git_refs_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/git/refs{/sha}"
                             :git_tags_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/git/tags{/sha}"
                             :git_url "git://github.com/davidgasquez/awesome-duckdb.git"
                             :has_discussions false
                             :has_downloads true
                             :has_issues true
                             :has_pages true
                             :has_projects true
                             :has_wiki false
                             :homepage "https://davidgasquez.github.io/awesome-duckdb/"
                             :hooks_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/hooks"
                             :html_url "https://github.com/davidgasquez/awesome-duckdb"
                             :id 589014131
                             :is_template false
                             :issue_comment_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/issues/comments{/number}"
                             :issue_events_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/issues/events{/number}"
                             :issues_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/issues{/number}"
                             :keys_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/keys{/key_id}"
                             :labels_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/labels{/name}"
                             :languages_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/languages"
                             :license {:key "cc0-1.0"
                                       :name "Creative Commons Zero v1.0 Universal"
                                       :node_id "MDc6TGljZW5zZTY="
                                       :spdx_id "CC0-1.0"
                                       :url "https://api.github.com/licenses/cc0-1.0"}
                             :merges_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/merges"
                             :milestones_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/milestones{/number}"
                             :name "awesome-duckdb"
                             :node_id "R_kgDOIxukcw "
                             :notifications_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/notifications{?since,all,participating}"
                             :open_issues 1
                             :open_issues_count 1
                             :owner {:avatar_url "https://avatars.githubusercontent.com/u/1682202?v=4"
                                     :events_url "https://api.github.com/users/davidgasquez/events{/privacy}"
                                     :followers_url "https://api.github.com/users/davidgasquez/followers"
                                     :following_url "https://api.github.com/users/davidgasquez/following{/other_user}"
                                     :gists_url "https://api.github.com/users/davidgasquez/gists{/gist_id}"
                                     :gravatar_id ""
                                     :html_url "https://github.com/davidgasquez"
                                     :id 1682202
                                     :login "davidgasquez "
                                     :node_id "MDQ6VXNlcjE2ODIyMDI="
                                     :organizations_url "https://api.github.com/users/davidgasquez/orgs"
                                     :received_events_url "https://api.github.com/users/davidgasquez/received_events"
                                     :repos_url "https://api.github.com/users/davidgasquez/repos"
                                     :site_admin false
                                     :starred_url "https://api.github.com/users/davidgasquez/starred{/owner}{/repo}"
                                     :subscriptions_url "https://api.github.com/users/davidgasquez/subscriptions"
                                     :type "User"
                                     :url "https://api.github.com/users/davidgasquez"
                                     :user_view_type "public"}
                             :private false
                             :pulls_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/pulls{/number}"
                             :pushed_at 1751618165000000
                             :releases_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/releases{/id}"
                             :score 1
                             :size 468
                             :ssh_url "git@github.com:davidgasquez/awesome-duckdb.git"
                             :stargazers_count 1910
                             :stargazers_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/stargazers"
                             :statuses_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/statuses/{sha}"
                             :subscribers_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/subscribers"
                             :subscription_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/subscription"
                             :svn_url "https://github.com/davidgasquez/awesome-duckdb"
                             :tags_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/tags"
                             :teams_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/teams"
                             :topics @["awesome" "awesome-list\x90"]
                             :trees_url "https://api.github.com/repos/davidgasquez/awesome-duckdb/git/trees{/sha}"
                             :updated_at 1751837059000000
                             :url "https://api.github.com/repos/davidgasquez/awesome-duckdb"
                             :visibility "public"
                             :watchers 1910
                             :watchers_count 1910
                             :web_commit_signoff_required false}]
                   :total_count 3979}])
          ))

      (with [result (db/query conn `
            CREATE TABLE github_raw_data AS
            SELECT
                *
            FROM
                read_json('https://api.github.com/search/repositories?q=duckdb&per_page=3')
          `)]
        (test (result/rows-changed result) 0)
        (test (result/describe-columns result :logical-type true)
              {:column-count 1
               :column-names ["Count"]
               :column-types [:bigint]})
        )
      )))
# TO BE CONTINUED...
