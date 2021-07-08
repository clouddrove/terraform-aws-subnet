// Managed By : CloudDrove
// Description : This Terratest is used to test the Terraform public private subnet module.
// Copyright @ CloudDrove. All Right Reserved.
package test

import (
	"testing"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func Test(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../../_example/public-private-subnet",
		Upgrade:      true,
	}

	// This will run 'terraform init' and 'terraform application' and will fail the test if any errors occur
	terraform.InitAndApply(t, terraformOptions)

	// To clean up any resources that have been created, run 'terraform destroy' towards the end of the test
	defer terraform.Destroy(t, terraformOptions)

	// To get the value of an output variable, run 'terraform output'
	publicSubnetCidrs := terraform.OutputList(t, terraformOptions, "public_subnet_cidrs")
	privateSubnetCidrs := terraform.OutputList(t, terraformOptions, "private_subnet_cidrs")
	publicTags := terraform.OutputMap(t, terraformOptions, "public_tags")
	privateTags := terraform.OutputMap(t, terraformOptions, "private_tags")

	//Expected Values
	expectedPublicSubnetCidrs := []string{"10.0.96.0/19", "10.0.128.0/19", "10.0.160.0/19"}
	expectedPrivateSubnetCidrs := []string{"10.0.0.0/19", "10.0.32.0/19", "10.0.64.0/19"}

	// Check that we get back the outputs that we expect
	assert.Equal(t, expectedPublicSubnetCidrs, publicSubnetCidrs)
	assert.Equal(t, expectedPrivateSubnetCidrs, privateSubnetCidrs)
	assert.Equal(t, "subnets-test-public", publicTags["Name"])
	assert.Equal(t, "subnets-test-private", privateTags["Name"])
}
