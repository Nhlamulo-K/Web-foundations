# School Database Design

## Tables

### Students

The `students` table stores information about each student. It contains a unique student ID, the student's name and their email address. The ID is the primary key, while the email address is required and must be unique so that two students cannot use the same email address.

### Courses

The `courses` table stores information about the courses offered by the school. Each course has a unique ID and a course name. The ID is the primary key.

### Enrolments

The `enrolments` table records which students are enrolled in which courses. It contains the student ID, course ID and the student's grade. The student ID and course ID are foreign keys that reference the `students` and `courses` tables. A unique constraint on the combination of `student_id` and `course_id` prevents the same student from enrolling in the same course more than once.

## Relationships

A student can have many enrolments, while each enrolment belongs to one student. This is a one-to-many relationship between students and enrolments.

A course can also have many enrolments, while each enrolment belongs to one course. This is a one-to-many relationship between courses and enrolments.

Students and courses therefore have a many-to-many relationship. One student can take many courses, and one course can have many students. The `enrolments` table is needed as a join table because it connects the students and courses and also stores additional information about the relationship, such as the student's grade.

## Index

I would add an index on `enrolments.student_id` because student IDs are frequently used when finding all courses belonging to a particular student. An index can make these lookups faster, especially when the database contains many enrolments.

## SQL or NoSQL

I would choose SQL for this system because the data has clear relationships between students, courses and enrolments. The database needs primary keys, foreign keys, unique constraints and joins to retrieve related information. The structure is also relatively consistent, with students, courses and enrolments having well-defined fields. A relational SQL database such as SQLite or PostgreSQL is therefore a better fit than a NoSQL database for this system.
