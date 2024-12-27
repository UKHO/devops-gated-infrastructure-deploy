# Update Guide

This guide details how to upgrade from version to version incrementally.

## 1.0.0 -> 2.0.0 Breaking Change - Replaced Parameter

The parameter `VariablesTemplateRelativePath` has been removed as of version 2.0.0 and superseded by new parameter `JobsVariablesMappings` for greater functionality and simplicity of design. However, usage of variable template is still possible with the newer parameter with adjustments.

```yaml
      - template: template.yml@GatedInfrastructureDeploy
        parameters:
          #...
          VariablesTemplateRelativePath: /pipeline/infrastructure-pipeline/vars-dev-deploy.yml
          #...
```

Becomes

```yaml
      - template: template.yml@GatedInfrastructureDeploy
        parameters:
          #...
          JobsVariableMappings:
            template: ${{variables['variables['System.DefaultWorkingDirectory']}}/pipeline/infrastructure-pipeline/vars-dev-deploy.yml@self
          #...
```

Alternatively, the content of the variables template can be passed in via `name` & `group` style variables. See [JobsVariablesMappings in detail](template-parameters-in-detail.md#jobsvariablemappings) for more information.