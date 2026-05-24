(import /src/db)
(import /src/result)

(use judge)

(deftest "github_repositories.json'"
  (with [db (db/open ":memory:")]
    (with [conn (db/connect db)]
      (with [result (db/query conn `
            SELECT
                *
            FROM
                read_json('test/resources/github_repositories.json')
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
                           {:child-type [:struct
                                         {:key-types [:bigint
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :bool
                                                      [:struct
                                                       {:key-types [:varchar
                                                                    :bigint
                                                                    :varchar
                                                                    :varchar
                                                                    :varchar
                                                                    :varchar
                                                                    :varchar
                                                                    :varchar
                                                                    :varchar
                                                                    :varchar
                                                                    :varchar
                                                                    :varchar
                                                                    :varchar
                                                                    :varchar
                                                                    :varchar
                                                                    :varchar
                                                                    :varchar
                                                                    :varchar
                                                                    :bool]
                                                        :keys [:login
                                                               :id
                                                               :node_id
                                                               :avatar_url
                                                               :gravatar_id
                                                               :url
                                                               :html_url
                                                               :followers_url
                                                               :following_url
                                                               :gists_url
                                                               :starred_url
                                                               :subscriptions_url
                                                               :organizations_url
                                                               :repos_url
                                                               :events_url
                                                               :received_events_url
                                                               :type
                                                               :user_view_type
                                                               :site_admin]}]
                                                      :varchar
                                                      :varchar
                                                      :bool
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :timestamp
                                                      :timestamp
                                                      :timestamp
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :varchar
                                                      :bigint
                                                      :bigint
                                                      :bigint
                                                      :varchar
                                                      :bool
                                                      :bool
                                                      :bool
                                                      :bool
                                                      :bool
                                                      :bool
                                                      :bigint
                                                      :varchar
                                                      :bool
                                                      :bool
                                                      :bigint
                                                      [:struct
                                                       {:key-types [:varchar
                                                                    :varchar
                                                                    :varchar
                                                                    :varchar
                                                                    :varchar]
                                                        :keys [:key :name :spdx_id :url :node_id]}]
                                                      :bool
                                                      :bool
                                                      :bool
                                                      [:list {:child-type :varchar}]
                                                      :varchar
                                                      :bigint
                                                      :bigint
                                                      :bigint
                                                      :varchar
                                                      :double]
                                          :keys [:id
                                                 :node_id
                                                 :name
                                                 :full_name
                                                 :private
                                                 :owner
                                                 :html_url
                                                 :description
                                                 :fork
                                                 :url
                                                 :forks_url
                                                 :keys_url
                                                 :collaborators_url
                                                 :teams_url
                                                 :hooks_url
                                                 :issue_events_url
                                                 :events_url
                                                 :assignees_url
                                                 :branches_url
                                                 :tags_url
                                                 :blobs_url
                                                 :git_tags_url
                                                 :git_refs_url
                                                 :trees_url
                                                 :statuses_url
                                                 :languages_url
                                                 :stargazers_url
                                                 :contributors_url
                                                 :subscribers_url
                                                 :subscription_url
                                                 :commits_url
                                                 :git_commits_url
                                                 :comments_url
                                                 :issue_comment_url
                                                 :contents_url
                                                 :compare_url
                                                 :merges_url
                                                 :archive_url
                                                 :downloads_url
                                                 :issues_url
                                                 :pulls_url
                                                 :milestones_url
                                                 :notifications_url
                                                 :labels_url
                                                 :releases_url
                                                 :deployments_url
                                                 :created_at
                                                 :updated_at
                                                 :pushed_at
                                                 :git_url
                                                 :ssh_url
                                                 :clone_url
                                                 :svn_url
                                                 :homepage
                                                 :size
                                                 :stargazers_count
                                                 :watchers_count
                                                 :language
                                                 :has_issues
                                                 :has_projects
                                                 :has_downloads
                                                 :has_wiki
                                                 :has_pages
                                                 :has_discussions
                                                 :forks_count
                                                 :mirror_url
                                                 :archived
                                                 :disabled
                                                 :open_issues_count
                                                 :license
                                                 :allow_forking
                                                 :is_template
                                                 :web_commit_signoff_required
                                                 :topics
                                                 :visibility
                                                 :forks
                                                 :open_issues
                                                 :watchers
                                                 :default_branch
                                                 :score]}]}]]})

        (let [columns (result/fetch-columns result)]
          (test columns
            {:column @column-from-name
             :column-count 3
             :column-names ["total_count"
                            "incomplete_results"
                            "items"]
             :column-types [:bigint :bool :list]
             :columns @[@[2777]
                        @[false]
                        @[@[{:allow_forking true
                             :archive_url "https://api.github.com/repos/janet-lang/janet/{archive_format}{/ref}"
                             :archived false
                             :assignees_url "https://api.github.com/repos/janet-lang/janet/assignees{/user}"
                             :blobs_url "https://api.github.com/repos/janet-lang/janet/git/blobs{/sha}"
                             :branches_url "https://api.github.com/repos/janet-lang/janet/branches{/branch}"
                             :clone_url "https://github.com/janet-lang/janet.git"
                             :collaborators_url "https://api.github.com/repos/janet-lang/janet/collaborators{/collaborator}"
                             :comments_url "https://api.github.com/repos/janet-lang/janet/comments{/number}"
                             :commits_url "https://api.github.com/repos/janet-lang/janet/commits{/sha}"
                             :compare_url "https://api.github.com/repos/janet-lang/janet/compare/{base}...{head}"
                             :contents_url "https://api.github.com/repos/janet-lang/janet/contents/{+path}"
                             :contributors_url "https://api.github.com/repos/janet-lang/janet/contributors"
                             :created_at 1489122515000000
                             :default_branch "master"
                             :deployments_url "https://api.github.com/repos/janet-lang/janet/deployments"
                             :description "A dynamic language and bytecode vm"
                             :disabled false
                             :downloads_url "https://api.github.com/repos/janet-lang/janet/downloads"
                             :events_url "https://api.github.com/repos/janet-lang/janet/events"
                             :fork false
                             :forks 245
                             :forks_count 245
                             :forks_url "https://api.github.com/repos/janet-lang/janet/forks"
                             :full_name "janet-lang/janet"
                             :git_commits_url "https://api.github.com/repos/janet-lang/janet/git/commits{/sha}"
                             :git_refs_url "https://api.github.com/repos/janet-lang/janet/git/refs{/sha}"
                             :git_tags_url "https://api.github.com/repos/janet-lang/janet/git/tags{/sha}"
                             :git_url "git://github.com/janet-lang/janet.git"
                             :has_discussions true
                             :has_downloads true
                             :has_issues true
                             :has_pages false
                             :has_projects true
                             :has_wiki false
                             :homepage "https://janet-lang.org"
                             :hooks_url "https://api.github.com/repos/janet-lang/janet/hooks"
                             :html_url "https://github.com/janet-lang/janet"
                             :id 84521458
                             :is_template false
                             :issue_comment_url "https://api.github.com/repos/janet-lang/janet/issues/comments{/number}"
                             :issue_events_url "https://api.github.com/repos/janet-lang/janet/issues/events{/number}"
                             :issues_url "https://api.github.com/repos/janet-lang/janet/issues{/number}"
                             :keys_url "https://api.github.com/repos/janet-lang/janet/keys{/key_id}"
                             :labels_url "https://api.github.com/repos/janet-lang/janet/labels{/name}"
                             :language "C"
                             :languages_url "https://api.github.com/repos/janet-lang/janet/languages"
                             :license {:key "mit"
                                       :name "MIT License"
                                       :node_id "MDc6TGljZW5zZTEz"
                                       :spdx_id "MIT"
                                       :url "https://api.github.com/licenses/mit"}
                             :merges_url "https://api.github.com/repos/janet-lang/janet/merges"
                             :milestones_url "https://api.github.com/repos/janet-lang/janet/milestones{/number}"
                             :name "janet"
                             :node_id "MDEwOlJlcG9zaXRvcnk4NDUyMTQ1OA=="
                             :notifications_url "https://api.github.com/repos/janet-lang/janet/notifications{?since,all,participating}"
                             :open_issues 55
                             :open_issues_count 55
                             :owner {:avatar_url "https://avatars.githubusercontent.com/u/45798268?v=4"
                                     :events_url "https://api.github.com/users/janet-lang/events{/privacy}"
                                     :followers_url "https://api.github.com/users/janet-lang/followers"
                                     :following_url "https://api.github.com/users/janet-lang/following{/other_user}"
                                     :gists_url "https://api.github.com/users/janet-lang/gists{/gist_id}"
                                     :gravatar_id ""
                                     :html_url "https://github.com/janet-lang"
                                     :id 45798268
                                     :login "janet-lang"
                                     :node_id "MDEyOk9yZ2FuaXphdGlvbjQ1Nzk4MjY4"
                                     :organizations_url "https://api.github.com/users/janet-lang/orgs"
                                     :received_events_url "https://api.github.com/users/janet-lang/received_events"
                                     :repos_url "https://api.github.com/users/janet-lang/repos"
                                     :site_admin false
                                     :starred_url "https://api.github.com/users/janet-lang/starred{/owner}{/repo}"
                                     :subscriptions_url "https://api.github.com/users/janet-lang/subscriptions"
                                     :type "Organization"
                                     :url "https://api.github.com/users/janet-lang"
                                     :user_view_type "public"}
                             :private false
                             :pulls_url "https://api.github.com/repos/janet-lang/janet/pulls{/number}"
                             :pushed_at 1752449756000000
                             :releases_url "https://api.github.com/repos/janet-lang/janet/releases{/id}"
                             :score 1
                             :size 14918
                             :ssh_url "git@github.com:janet-lang/janet.git"
                             :stargazers_count 3943
                             :stargazers_url "https://api.github.com/repos/janet-lang/janet/stargazers"
                             :statuses_url "https://api.github.com/repos/janet-lang/janet/statuses/{sha}"
                             :subscribers_url "https://api.github.com/repos/janet-lang/janet/subscribers"
                             :subscription_url "https://api.github.com/repos/janet-lang/janet/subscription"
                             :svn_url "https://github.com/janet-lang/janet"
                             :tags_url "https://api.github.com/repos/janet-lang/janet/tags"
                             :teams_url "https://api.github.com/repos/janet-lang/janet/teams"
                             :topics @["c"
                                       "functional-language"
                                       "imperative-language"
                                       "interpreter"
                                       "language"
                                       "lisp"
                                       "macros"
                                       "repl"
                                       "vm"]
                             :trees_url "https://api.github.com/repos/janet-lang/janet/git/trees{/sha}"
                             :updated_at 1754128691000000
                             :url "https://api.github.com/repos/janet-lang/janet"
                             :visibility "public"
                             :watchers 3943
                             :watchers_count 3943
                             :web_commit_signoff_required false}
                            {:allow_forking true
                             :archive_url "https://api.github.com/repos/janet-lang/janet-lang.org/{archive_format}{/ref}"
                             :archived false
                             :assignees_url "https://api.github.com/repos/janet-lang/janet-lang.org/assignees{/user}"
                             :blobs_url "https://api.github.com/repos/janet-lang/janet-lang.org/git/blobs{/sha}"
                             :branches_url "https://api.github.com/repos/janet-lang/janet-lang.org/branches{/branch}"
                             :clone_url "https://github.com/janet-lang/janet-lang.org.git"
                             :collaborators_url "https://api.github.com/repos/janet-lang/janet-lang.org/collaborators{/collaborator}"
                             :comments_url "https://api.github.com/repos/janet-lang/janet-lang.org/comments{/number}"
                             :commits_url "https://api.github.com/repos/janet-lang/janet-lang.org/commits{/sha}"
                             :compare_url "https://api.github.com/repos/janet-lang/janet-lang.org/compare/{base}...{head}"
                             :contents_url "https://api.github.com/repos/janet-lang/janet-lang.org/contents/{+path}"
                             :contributors_url "https://api.github.com/repos/janet-lang/janet-lang.org/contributors"
                             :created_at 1537629537000000
                             :default_branch "master"
                             :deployments_url "https://api.github.com/repos/janet-lang/janet-lang.org/deployments"
                             :description "Website for janet"
                             :disabled false
                             :downloads_url "https://api.github.com/repos/janet-lang/janet-lang.org/downloads"
                             :events_url "https://api.github.com/repos/janet-lang/janet-lang.org/events"
                             :fork false
                             :forks 67
                             :forks_count 67
                             :forks_url "https://api.github.com/repos/janet-lang/janet-lang.org/forks"
                             :full_name "janet-lang/janet-lang.org"
                             :git_commits_url "https://api.github.com/repos/janet-lang/janet-lang.org/git/commits{/sha}"
                             :git_refs_url "https://api.github.com/repos/janet-lang/janet-lang.org/git/refs{/sha}"
                             :git_tags_url "https://api.github.com/repos/janet-lang/janet-lang.org/git/tags{/sha}"
                             :git_url "git://github.com/janet-lang/janet-lang.org.git"
                             :has_discussions false
                             :has_downloads true
                             :has_issues true
                             :has_pages false
                             :has_projects true
                             :has_wiki true
                             :homepage "https://janet-lang.org"
                             :hooks_url "https://api.github.com/repos/janet-lang/janet-lang.org/hooks"
                             :html_url "https://github.com/janet-lang/janet-lang.org"
                             :id 149888787
                             :is_template false
                             :issue_comment_url "https://api.github.com/repos/janet-lang/janet-lang.org/issues/comments{/number}"
                             :issue_events_url "https://api.github.com/repos/janet-lang/janet-lang.org/issues/events{/number}"
                             :issues_url "https://api.github.com/repos/janet-lang/janet-lang.org/issues{/number}"
                             :keys_url "https://api.github.com/repos/janet-lang/janet-lang.org/keys{/key_id}"
                             :labels_url "https://api.github.com/repos/janet-lang/janet-lang.org/labels{/name}"
                             :language "HTML"
                             :languages_url "https://api.github.com/repos/janet-lang/janet-lang.org/languages"
                             :license {:key "mit"
                                       :name "MIT License"
                                       :node_id "MDc6TGljZW5zZTEz"
                                       :spdx_id "MIT"
                                       :url "https://api.github.com/licenses/mit"}
                             :merges_url "https://api.github.com/repos/janet-lang/janet-lang.org/merges"
                             :milestones_url "https://api.github.com/repos/janet-lang/janet-lang.org/milestones{/number}"
                             :name "janet-lang.org"
                             :node_id "MDEwOlJlcG9zaXRvcnkxNDk4ODg3ODc="
                             :notifications_url "https://api.github.com/repos/janet-lang/janet-lang.org/notifications{?since,all,participating}"
                             :open_issues 17
                             :open_issues_count 17
                             :owner {:avatar_url "https://avatars.githubusercontent.com/u/45798268?v=4"
                                     :events_url "https://api.github.com/users/janet-lang/events{/privacy}"
                                     :followers_url "https://api.github.com/users/janet-lang/followers"
                                     :following_url "https://api.github.com/users/janet-lang/following{/other_user}"
                                     :gists_url "https://api.github.com/users/janet-lang/gists{/gist_id}"
                                     :gravatar_id ""
                                     :html_url "https://github.com/janet-lang"
                                     :id 45798268
                                     :login "janet-lang"
                                     :node_id "MDEyOk9yZ2FuaXphdGlvbjQ1Nzk4MjY4"
                                     :organizations_url "https://api.github.com/users/janet-lang/orgs"
                                     :received_events_url "https://api.github.com/users/janet-lang/received_events"
                                     :repos_url "https://api.github.com/users/janet-lang/repos"
                                     :site_admin false
                                     :starred_url "https://api.github.com/users/janet-lang/starred{/owner}{/repo}"
                                     :subscriptions_url "https://api.github.com/users/janet-lang/subscriptions"
                                     :type "Organization"
                                     :url "https://api.github.com/users/janet-lang"
                                     :user_view_type "public"}
                             :private false
                             :pulls_url "https://api.github.com/repos/janet-lang/janet-lang.org/pulls{/number}"
                             :pushed_at 1751545363000000
                             :releases_url "https://api.github.com/repos/janet-lang/janet-lang.org/releases{/id}"
                             :score 1
                             :size 25758
                             :ssh_url "git@github.com:janet-lang/janet-lang.org.git"
                             :stargazers_count 99
                             :stargazers_url "https://api.github.com/repos/janet-lang/janet-lang.org/stargazers"
                             :statuses_url "https://api.github.com/repos/janet-lang/janet-lang.org/statuses/{sha}"
                             :subscribers_url "https://api.github.com/repos/janet-lang/janet-lang.org/subscribers"
                             :subscription_url "https://api.github.com/repos/janet-lang/janet-lang.org/subscription"
                             :svn_url "https://github.com/janet-lang/janet-lang.org"
                             :tags_url "https://api.github.com/repos/janet-lang/janet-lang.org/tags"
                             :teams_url "https://api.github.com/repos/janet-lang/janet-lang.org/teams"
                             :topics @[]
                             :trees_url "https://api.github.com/repos/janet-lang/janet-lang.org/git/trees{/sha}"
                             :updated_at 1751545377000000
                             :url "https://api.github.com/repos/janet-lang/janet-lang.org"
                             :visibility "public"
                             :watchers 99
                             :watchers_count 99
                             :web_commit_signoff_required false}
                            {:allow_forking true
                             :archive_url "https://api.github.com/repos/janet-lang/jaylib/{archive_format}{/ref}"
                             :archived false
                             :assignees_url "https://api.github.com/repos/janet-lang/jaylib/assignees{/user}"
                             :blobs_url "https://api.github.com/repos/janet-lang/jaylib/git/blobs{/sha}"
                             :branches_url "https://api.github.com/repos/janet-lang/jaylib/branches{/branch}"
                             :clone_url "https://github.com/janet-lang/jaylib.git"
                             :collaborators_url "https://api.github.com/repos/janet-lang/jaylib/collaborators{/collaborator}"
                             :comments_url "https://api.github.com/repos/janet-lang/jaylib/comments{/number}"
                             :commits_url "https://api.github.com/repos/janet-lang/jaylib/commits{/sha}"
                             :compare_url "https://api.github.com/repos/janet-lang/jaylib/compare/{base}...{head}"
                             :contents_url "https://api.github.com/repos/janet-lang/jaylib/contents/{+path}"
                             :contributors_url "https://api.github.com/repos/janet-lang/jaylib/contributors"
                             :created_at 1568493837000000
                             :default_branch "master"
                             :deployments_url "https://api.github.com/repos/janet-lang/jaylib/deployments"
                             :description "Janet bindings to Raylib"
                             :disabled false
                             :downloads_url "https://api.github.com/repos/janet-lang/jaylib/downloads"
                             :events_url "https://api.github.com/repos/janet-lang/jaylib/events"
                             :fork false
                             :forks 41
                             :forks_count 41
                             :forks_url "https://api.github.com/repos/janet-lang/jaylib/forks"
                             :full_name "janet-lang/jaylib"
                             :git_commits_url "https://api.github.com/repos/janet-lang/jaylib/git/commits{/sha}"
                             :git_refs_url "https://api.github.com/repos/janet-lang/jaylib/git/refs{/sha}"
                             :git_tags_url "https://api.github.com/repos/janet-lang/jaylib/git/tags{/sha}"
                             :git_url "git://github.com/janet-lang/jaylib.git"
                             :has_discussions false
                             :has_downloads true
                             :has_issues true
                             :has_pages false
                             :has_projects true
                             :has_wiki true
                             :hooks_url "https://api.github.com/repos/janet-lang/jaylib/hooks"
                             :html_url "https://github.com/janet-lang/jaylib"
                             :id 208501458
                             :is_template false
                             :issue_comment_url "https://api.github.com/repos/janet-lang/jaylib/issues/comments{/number}"
                             :issue_events_url "https://api.github.com/repos/janet-lang/jaylib/issues/events{/number}"
                             :issues_url "https://api.github.com/repos/janet-lang/jaylib/issues{/number}"
                             :keys_url "https://api.github.com/repos/janet-lang/jaylib/keys{/key_id}"
                             :labels_url "https://api.github.com/repos/janet-lang/jaylib/labels{/name}"
                             :language "C"
                             :languages_url "https://api.github.com/repos/janet-lang/jaylib/languages"
                             :license {:key "mit"
                                       :name "MIT License"
                                       :node_id "MDc6TGljZW5zZTEz"
                                       :spdx_id "MIT"
                                       :url "https://api.github.com/licenses/mit"}
                             :merges_url "https://api.github.com/repos/janet-lang/jaylib/merges"
                             :milestones_url "https://api.github.com/repos/janet-lang/jaylib/milestones{/number}"
                             :name "jaylib"
                             :node_id "MDEwOlJlcG9zaXRvcnkyMDg1MDE0NTg="
                             :notifications_url "https://api.github.com/repos/janet-lang/jaylib/notifications{?since,all,participating}"
                             :open_issues 13
                             :open_issues_count 13
                             :owner {:avatar_url "https://avatars.githubusercontent.com/u/45798268?v=4"
                                     :events_url "https://api.github.com/users/janet-lang/events{/privacy}"
                                     :followers_url "https://api.github.com/users/janet-lang/followers"
                                     :following_url "https://api.github.com/users/janet-lang/following{/other_user}"
                                     :gists_url "https://api.github.com/users/janet-lang/gists{/gist_id}"
                                     :gravatar_id ""
                                     :html_url "https://github.com/janet-lang"
                                     :id 45798268
                                     :login "janet-lang"
                                     :node_id "MDEyOk9yZ2FuaXphdGlvbjQ1Nzk4MjY4"
                                     :organizations_url "https://api.github.com/users/janet-lang/orgs"
                                     :received_events_url "https://api.github.com/users/janet-lang/received_events"
                                     :repos_url "https://api.github.com/users/janet-lang/repos"
                                     :site_admin false
                                     :starred_url "https://api.github.com/users/janet-lang/starred{/owner}{/repo}"
                                     :subscriptions_url "https://api.github.com/users/janet-lang/subscriptions"
                                     :type "Organization"
                                     :url "https://api.github.com/users/janet-lang"
                                     :user_view_type "public"}
                             :private false
                             :pulls_url "https://api.github.com/repos/janet-lang/jaylib/pulls{/number}"
                             :pushed_at 1716030970000000
                             :releases_url "https://api.github.com/repos/janet-lang/jaylib/releases{/id}"
                             :score 1
                             :size 2521
                             :ssh_url "git@github.com:janet-lang/jaylib.git"
                             :stargazers_count 171
                             :stargazers_url "https://api.github.com/repos/janet-lang/jaylib/stargazers"
                             :statuses_url "https://api.github.com/repos/janet-lang/jaylib/statuses/{sha}"
                             :subscribers_url "https://api.github.com/repos/janet-lang/jaylib/subscribers"
                             :subscription_url "https://api.github.com/repos/janet-lang/jaylib/subscription"
                             :svn_url "https://github.com/janet-lang/jaylib"
                             :tags_url "https://api.github.com/repos/janet-lang/jaylib/tags"
                             :teams_url "https://api.github.com/repos/janet-lang/jaylib/teams"
                             :topics @[]
                             :trees_url "https://api.github.com/repos/janet-lang/jaylib/git/trees{/sha}"
                             :updated_at 1753640573000000
                             :url "https://api.github.com/repos/janet-lang/jaylib"
                             :visibility "public"
                             :watchers 171
                             :watchers_count 171
                             :web_commit_signoff_required false}]]]
             :row-count 1}))))))
