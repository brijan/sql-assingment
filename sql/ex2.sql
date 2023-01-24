With _A as (
 SELECT 
	CalendarDate,
    Employee,
    Department,
    Salary,
    FIRST_VALUE(Salary)  OVER(PARTITION by Employee ORDER by CalendarDate) FirstSalary,
    LAG(Salary, 1) OVER(PARTITION by Employee ORDER by CalendarDate) PreviousSalary,
    LEAD(Salary, 1) OVER(PARTITION by Employee ORDER by CalendarDate) NextSalary,
    SUM(Salary) OVER (PARTITION BY CalendarDate,Department) AS SumOfDepartmentSalary
    FROM Salary
 )
SELECT 
    _A.CalendarDate,
    _A.Employee,
    _A.Department,
    _A.Salary,
    _A.FirstSalary,
    _A.PreviousSalary,
    _A.NextSalary,
    _A.SumOfDepartmentSalary,
    SUM(_A.SumOfDepartmentSalary) OVER(partition by Employee order by CalendarDate) as CumulativeSumofDepartmentsSalary
    FROM _A
ORDER BY Employee, CalendarDate