
# Import the parent module to test

if (Get-Module -Name PSHyperV) {
    Remove-Module -Name PSHyperV
}
Import-Module $ModuleManifestPath -force

InModuleScope PSHyperV {
    Describe 'ModuleStructure' {
        It 'Passes Test-ModuleManifest' {
            {Test-ModuleManifest -Path "$PSScriptRoot\..\PSHyperV.psd1" | Should Be True
        }

        $psdata = (Get-Module PSHyperV  ).PrivateData.psdata
        It "Should have a project uri" {
            $psdata.projecturi | Should Match "^http"
        } -pending

        It "Should have one or more tags" {
            $psdata.tags.count | Should BeGreaterThan 0
        } -pending

        It "Should have markdown documents folder" {
            Get-Childitem $psscriptroot\..\docs\*md | Should Exist
        } -pending

        It "Should have an external help file" {
            $cult = (Get-Culture).name
            Get-Childitem $psscriptroot\..\$cult\*-help.xml | Should Exist
        } -pending

        It "Should have a README file" {
            Get-Childitem $psscriptroot\..\README.md | Should Exist
        }

        It "Should have a License file" {
            Get-Childitem $psscriptroot\..\License.txt | Should Exist
        }
    }
    Describe Stop-VMGroup {

        Context Structure {
            $thiscmd = Get-Item Function:Stop-VMGroup
            $pathParam = $thiscmd.Parameters["Path"].Attributes.where({$_.typeid.name -eq 'ParameterAttribute'})

            It "Should use cmdletbinding" {
                $thiscmd.CmdletBinding | should Be True
            }

            It "Should have documentation" {
                $h = Get-Help Stop-VMGroup
                $h.description | Should Not Be Null
                $h.examples | Should Not Be Null
            }
        }
        Context Input {
            It "should accept parameter values" {
                #insert test
            }
        }
        Context Output {
            It "Should write an object to the pipeline" {
                #Insert your test
            }
        }
    }
    Describe Start-VMGroup {

        Context Structure {
            $thiscmd = Get-Item Function:Start-VMGroup
            $pathParam = $thiscmd.Parameters["Path"].Attributes.where({$_.typeid.name -eq 'ParameterAttribute'})

            It "Should use cmdletbinding" {
                $thiscmd.CmdletBinding | should Be True
            }

            It "Should have documentation" {
                $h = Get-Help Start-VMGroup
                $h.description | Should Not Be Null
                $h.examples | Should Not Be Null
            }
        }
        Context Input {
            It "should accept parameter values" {
                #insert test
            }
        }
        Context Output {
            It "Should write an object to the pipeline" {
                #Insert your test
            }
        }
    }
    Describe Expand-VMGroup {

        Context Structure {
            $thiscmd = Get-Item Function:Expand-VMGroup
            $pathParam = $thiscmd.Parameters["Path"].Attributes.where({$_.typeid.name -eq 'ParameterAttribute'})

            It "Should use cmdletbinding" {
                $thiscmd.CmdletBinding | should Be True
            }

            It "Should have documentation" {
                $h = Get-Help Expand-VMGroup
                $h.description | Should Not Be Null
                $h.examples | Should Not Be Null
            }
        }
        Context Input {
            It "should accept parameter values" {
                #insert test
            }
        }
        Context Output {
            It "Should write an object to the pipeline" {
                #Insert your test
            }
        }
    }

} #in module scope
