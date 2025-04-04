-- Interogarea 1: numarul total de angajați din baza de date 
SELECT COUNT(*) AS numar_total_angajati FROM employees;

-- Interogarea 2: numele angajatilor dintr-un departament specific(luam IT ca exemplu) aici ar 10 interogari
SELECT e.first_name AS prenume, e.last_name AS nume
FROM employees e
JOIN departments d ON e.department_id = d.department_id
WHERE d.department_name = 'IT';

-- Interogarea 3: salariile maxime si minime per departament
SELECT d.department_name AS departament,
       MAX(s.salary) AS salariu_maxim,
       MIN(s.salary) AS salariu_minim
FROM departments d
JOIN employees e ON d.department_id = e.department_id
JOIN salaries s ON e.employee_id = s.employee_id
GROUP BY d.department_name
ORDER BY d.department_name;
