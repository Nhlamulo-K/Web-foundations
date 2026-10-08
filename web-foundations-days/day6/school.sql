CREATE TABLE IF NOT EXISTS students (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS courses (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS enrolments (
    id INTEGER PRIMARY KEY,
    student_id INTEGER NOT NULL,
    course_id INTEGER NOT NULL,
    grade INTEGER,
    FOREIGN KEY (student_id) REFERENCES students(id),
    FOREIGN KEY (course_id) REFERENCES courses(id),
    UNIQUE (student_id, course_id)
);

INSERT INTO students (id, name, email) VALUES
    (1, 'Nhlamulo Khoza', 'nhlamulo@example.com'),
    (2, 'Thabo Mokoena', 'thabo@example.com'),
    (3, 'Lerato Dlamini', 'lerato@example.com'),
    (4, 'Sipho Nkosi', 'sipho@example.com');

INSERT INTO courses (id, name) VALUES
    (1, 'Database Systems'),
    (2, 'Web Development'),
    (3, 'Software Engineering');

INSERT INTO enrolments (id, student_id, course_id, grade) VALUES
    (1, 1, 1, 85),
    (2, 1, 2, 78),
    (3, 2, 1, 72),
    (4, 2, 3, 88),
    (5, 3, 2, 91);

SELECT students.name AS student, courses.name AS course
FROM students
JOIN enrolments ON students.id = enrolments.student_id
JOIN courses ON enrolments.course_id = courses.id
WHERE students.name = 'Nhlamulo Khoza';

SELECT courses.name AS course, students.name AS student
FROM courses
JOIN enrolments ON courses.id = enrolments.course_id
JOIN students ON enrolments.student_id = students.id
WHERE courses.name = 'Database Systems';

SELECT courses.name AS course,
        COUNT(enrolments.student_id) AS student_count
FROM courses
LEFT JOIN enrolments ON courses.id = enrolments.course_id
GROUP BY courses.id, courses.name;

SELECT students.name
FROM students
LEFT JOIN enrolments ON students.id = enrolments.student_id
WHERE enrolments.id IS NULL;

UPDATE enrolments
SET grade = 90
WHERE student_id = 1
    AND course_id = 1;