##########################################################################
# Copyright 2015 ThoughtWorks, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##########################################################################

require 'spec_helper'
describe ApiV1::Config::Materials::MaterialRepresenter do
  shared_examples_for 'materials' do

    describe :serialize do
      it 'should render material with hal representation' do
        presenter              = ApiV1::Config::Materials::MaterialRepresenter.new(existing_material)
        actual_json            = presenter.to_hash(url_builder: UrlBuilder.new)
        expected_material_hash = material_hash
        expect(actual_json).to eq(expected_material_hash)
      end
    end

    describe :deserialize do
      it 'should convert hash to Material' do
        new_material = material_type.new
        presenter    = ApiV1::Config::Materials::MaterialRepresenter.new(new_material)
        presenter.from_hash(ApiV1::Config::Materials::MaterialRepresenter.new(existing_material).to_hash(url_builder: UrlBuilder.new))
        expect(new_material.autoUpdate).to eq(existing_material.autoUpdate)
        expect(new_material.name).to eq(existing_material.name)
        expect(new_material).to eq(existing_material)
      end
    end

  end

  describe :git do
    it_should_behave_like 'materials'

    def existing_material
      MaterialConfigsMother.gitMaterialConfig
    end

    def material_type
      GitMaterialConfig
    end

    it "should serialize material without name" do
      presenter   = ApiV1::Config::Materials::MaterialRepresenter.prepare(GitMaterialConfig.new("http://user:password@funk.com/blank"))
      actual_json = presenter.to_hash(url_builder: UrlBuilder.new)
      expect(actual_json).to eq(git_material_basic_hash)
    end

    it "should deserialize material without name" do
      presenter           = ApiV1::Config::Materials::MaterialRepresenter.new(GitMaterialConfig.new)
      deserialized_object = presenter.from_hash({
                                                  type:       'git',
                                                  attributes: {
                                                    url:         "http://user:password@funk.com/blank",
                                                    branch:      "master",
                                                    auto_update: true,
                                                    name:        nil
                                                  }
                                                })
      expected            = GitMaterialConfig.new("http://user:password@funk.com/blank")
      expect(deserialized_object.autoUpdate).to eq(expected.autoUpdate)
      expect(deserialized_object.name.to_s).to eq("")
      expect(deserialized_object).to eq(expected)
    end

    it "should serialize pluggable scm material" do

      presenter   = ApiV1::Config::Materials::MaterialRepresenter.prepare(PluggableSCMMaterialConfig.new("23a28171-3d5a-4912-9f36-d4e1536281b0"))
      actual_json = presenter.to_hash(url_builder: UrlBuilder.new)
      expect(actual_json).to eq(scm_material_basic_hash)
    end

    it "should deserialize pluggable scm material" do
      presenter           = ApiV1::Config::Materials::MaterialRepresenter.new(PluggableSCMMaterialConfig.new)
      deserialized_object = presenter.from_hash({
                                                    type: "plugin",
                                                    attributes: {
                                                      ref: "23a28171-3d5a-4912-9f36-d4e1536281b0",
                                                      filter: {
                                                        ignore: [
                                                          "doc/**/*",
                                                          "foo/**/*"
                                                        ]
                                                      }
                                                    }
                                                })
      expect(deserialized_object.name.to_s).to eq("")
      expect(deserialized_object.getScmId).to eq("23a28171-3d5a-4912-9f36-d4e1536281b0")
      expect(deserialized_object.filter.getStringForDisplay).to eq("doc/**/*,foo/**/*")
    end

    it "should deserialize pluggable scm material with null filter" do
      presenter           = ApiV1::Config::Materials::MaterialRepresenter.new(PluggableSCMMaterialConfig.new)
      deserialized_object = presenter.from_hash({
                                                    type: "plugin",
                                                    attributes: {
                                                      ref: "23a28171-3d5a-4912-9f36-d4e1536281b0",
                                                      filter: nil
                                                    }
                                                })
      expect(deserialized_object.name.to_s).to eq("")
      expect(deserialized_object.getScmId).to eq("23a28171-3d5a-4912-9f36-d4e1536281b0")
      expect(ReflectionUtil::getField(deserialized_object, "filter")).to be_nil
    end

    def material_hash
      {
        type:       'git',
        attributes: {
          url:              "http://user:password@funk.com/blank",
          destination:      "destination",
          filter:           {
            ignore: %w(**/*.html **/foobar/)
          },
          branch:           'branch',
          submodule_folder: 'sub_module_folder',
          name:             'AwesomeGitMaterial',
          auto_update:      false
        }
      }
    end

    def git_material_basic_hash
      {
        type:       'git',
        attributes: {
          url:              "http://user:password@funk.com/blank",
          destination:      nil,
          filter:           nil,
          name:             nil,
          auto_update:      true,
          branch:           "master",
          submodule_folder: nil
        }
      }
    end

    def scm_material_basic_hash
      {
        type: "plugin",
        attributes: {
          ref: "23a28171-3d5a-4912-9f36-d4e1536281b0",
          filter: nil
        }
      }
    end
  end

  describe :svn do
    it_should_behave_like 'materials'

    def existing_material
      MaterialConfigsMother.svnMaterialConfig
    end

    def material_type
      SvnMaterialConfig
    end

    def material_hash
      {
        type:       'svn',
        attributes: {
          url:                "url",
          destination:        "svnDir",
          filter:             {
            ignore: [
                      "*.doc"
                    ]
          },
          name:               "svn-material",
          auto_update:        false,
          check_externals:    true,
          username:           "user",
          encrypted_password: GoCipher.new.encrypt("pass")
        }
      }
    end
  end

  describe :hg do
    it_should_behave_like 'materials'

    def existing_material
      MaterialConfigsMother.hgMaterialConfigFull
    end

    def material_type
      HgMaterialConfig
    end

    def material_hash
      {
        type:       'hg',
        attributes: {
          url:         "http://user:pass@domain/path##branch",
          destination: "dest-folder",
          filter:      {
            ignore: %w(**/*.html **/foobar/)
          },
          name:        "hg-material",
          auto_update: true
        }
      }
    end
  end

  describe :tfs do
    it_should_behave_like 'materials'

    def existing_material
      MaterialConfigsMother.tfsMaterialConfig
    end

    def material_type
      TfsMaterialConfig
    end

    def material_hash
      {
        type:       'tfs',
        attributes: {
          url:                "http://10.4.4.101:8080/tfs/Sample",
          destination:        "dest-folder",
          filter:             {
            ignore: %w(**/*.html **/foobar/)
          },
          domain:             "some_domain",
          username:           "loser",
          encrypted_password: com.thoughtworks.go.security.GoCipher.new.encrypt("passwd"),
          project_path:       "walk_this_path",
          name:               "tfs-material",
          auto_update:        true
        }
      }
    end
  end

  describe :p4 do
    it_should_behave_like 'materials'

    def existing_material
      MaterialConfigsMother.p4MaterialConfigFull
    end

    def material_type
      P4MaterialConfig
    end

    def material_hash
      {
        type:       'p4',
        attributes: {
          destination:        "dest-folder",
          filter:             {
            ignore: %w(**/*.html **/foobar/)
          },
          port:               "host:9876",
          username:           "user",
          encrypted_password: GoCipher.new.encrypt("password"),
          use_tickets:        true,
          view:               "view",
          name:               "p4-material",
          auto_update:        true
        }
      }
    end
  end

  describe :dependency do
    it_should_behave_like 'materials'

    def existing_material
      MaterialConfigsMother.dependencyMaterialConfig
    end

    def material_type
      DependencyMaterialConfig
    end

    def material_hash
      {
        type:       'dependency',
        attributes: {
          pipeline:    "pipeline-name",
          stage:       "stage-name",
          name:        "pipeline-name",
          auto_update: true
        }
      }
    end
  end

  describe :package do
    it "should represent a package material" do
      presenter   = ApiV1::Config::Materials::MaterialRepresenter.prepare(MaterialConfigsMother.packageMaterialConfig())
      actual_json = presenter.to_hash(url_builder: UrlBuilder.new)
      expect(actual_json).to eq(package_material_hash)
    end

    it "should deserialize" do
      presenter           = ApiV1::Config::Materials::MaterialRepresenter.prepare(PackageMaterialConfig.new)
      deserialized_object = presenter.from_hash(package_material_hash)
      expected            = MaterialConfigsMother.package_material_config()
      expect(deserialized_object.getPackageId).to eq(expected.getPackageId)
    end

    def package_material_hash
      {
        type:       'package',
        attributes: {
          ref: "p-id"
        }
      }
    end

  end

  describe :pluggable do
    it "should represent a pluggable scm material" do
      pluggable_scm_material = MaterialConfigsMother.pluggableSCMMaterialConfig()
      presenter              = ApiV1::Config::Materials::MaterialRepresenter.prepare(pluggable_scm_material)
      actual_json            = presenter.to_hash(url_builder: UrlBuilder.new)
      expect(actual_json).to eq(pluggable_scm_material_hash)
    end

    it "should deserialize" do
      presenter           = ApiV1::Config::Materials::MaterialRepresenter.new(PluggableSCMMaterialConfig.new)
      deserialized_object = presenter.from_hash(pluggable_scm_material_hash)
      expected            = MaterialConfigsMother.pluggableSCMMaterialConfig()
      expect(deserialized_object.getScmId).to eq("scm-id")
    end

    def pluggable_scm_material_hash
      {
        type:       'plugin',
        attributes: {
          ref:    "scm-id",
          filter: {
            ignore: %w(**/*.html **/foobar/)
          }
        }
      }
    end

  end
end
