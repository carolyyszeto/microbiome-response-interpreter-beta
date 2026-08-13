# User smoke test for v7

From the repository root, run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\user_smoke_test_v7.ps1
```

The test creates only `tmp_user_smoke/` and removes any earlier folder with that exact name. It reports one clear PASS/FAIL line per module and exits with code 1 on failure.

Hand-check return toy: T01 uses A=(3,4), R=(-2,-1), E=(1,3). Thus q=10/(5*sqrt(5))=0.894427191 and rho=sqrt(10)/5=0.632455532. T02 has q=15/(5*sqrt(10))=0.948683298 and rho=sqrt(5)/5=0.447213595. These values prove that R and E are separate inputs.
