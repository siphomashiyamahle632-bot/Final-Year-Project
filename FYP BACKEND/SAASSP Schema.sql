-- SAASSP DATABASE SCHEMA
-- Smart Academic Advisory & Student Success Platform
-- Database: SAASSP

CREATE DATABASE IF NOT EXISTS SAASSP;
USE SAASSP;

SET FOREIGN_KEY_CHECKS = 0;

-- DROP EXISTING TABLES
-- Child tables are dropped before parent tables

DROP TABLE IF EXISTS assessments;
DROP TABLE IF EXISTS attendance;
DROP TABLE IF EXISTS risk_predictions;
DROP TABLE IF EXISTS co_requisites;
DROP TABLE IF EXISTS prerequisites;
DROP TABLE IF EXISTS student_module_results;
DROP TABLE IF EXISTS modules;
DROP TABLE IF EXISTS academic_staff;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS programmes;
DROP TABLE IF EXISTS users;

-- 1. USERS
-- Stores authentication and role information for SAASSP users

CREATE TABLE users (
    user_id INT NOT NULL AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id),
    UNIQUE KEY uq_users_username (username),
    CONSTRAINT chk_users_role
        CHECK (
            role IN (
                'student',
                'academic_staff',
                'administrator'
            )
        )
) ENGINE=InnoDB;


-- 2. PROGRAMMES
-- Stores academic programme information

CREATE TABLE programmes (
    programme_id INT NOT NULL AUTO_INCREMENT,
    programme_code VARCHAR(20) NOT NULL,
    programme_name VARCHAR(100) NOT NULL,
    duration_years INT NOT NULL,
    total_credits INT NULL,
    PRIMARY KEY (programme_id),
    UNIQUE KEY uq_programmes_programme_code (programme_code),
    CONSTRAINT chk_programmes_duration
        CHECK (duration_years > 0),
    CONSTRAINT chk_programmes_total_credits
        CHECK (
            total_credits IS NULL
            OR total_credits >= 0
        )
) ENGINE=InnoDB;

-- 3. STUDENTS
-- Stores synthetic student profile information

CREATE TABLE students (
    student_id INT NOT NULL AUTO_INCREMENT,
    student_number VARCHAR(20) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    surname VARCHAR(50) NOT NULL,
    programme_id INT NOT NULL,
    current_year INT NOT NULL,
    status VARCHAR(20) NULL DEFAULT 'Active',
    user_id INT NULL,
    PRIMARY KEY (student_id),
    UNIQUE KEY uq_students_student_number (student_number),
    UNIQUE KEY uq_students_user_id (user_id),
    KEY idx_students_programme_id (programme_id),
    CONSTRAINT students_ibfk_1
        FOREIGN KEY (programme_id)
        REFERENCES programmes (programme_id),
    CONSTRAINT students_ibfk_2
        FOREIGN KEY (user_id)
        REFERENCES users (user_id),
    CONSTRAINT chk_students_current_year
        CHECK (current_year >= 1)
) ENGINE=InnoDB;

-- 4. ACADEMIC STAFF
-- Stores Academic Staff profile information
-- Authentication remains in the users table

CREATE TABLE academic_staff (
    staff_id INT NOT NULL AUTO_INCREMENT,
    staff_number VARCHAR(20) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    surname VARCHAR(50) NOT NULL,
    department VARCHAR(100) NOT NULL,
    academic_role VARCHAR(50) NOT NULL,
    programme_id INT NULL,
    user_id INT NULL,
    PRIMARY KEY (staff_id),
    UNIQUE KEY uq_academic_staff_staff_number (staff_number),
    UNIQUE KEY uq_academic_staff_user_id (user_id),
    KEY idx_academic_staff_programme_id (programme_id),
    CONSTRAINT academic_staff_ibfk_1
        FOREIGN KEY (programme_id)
        REFERENCES programmes (programme_id),
    CONSTRAINT academic_staff_ibfk_2
        FOREIGN KEY (user_id)
        REFERENCES users (user_id)
) ENGINE=InnoDB;

-- 5. MODULES
-- Stores modules belonging to configured programmes

CREATE TABLE modules (
    module_id INT NOT NULL AUTO_INCREMENT,
    module_code VARCHAR(20) NOT NULL,
    module_name VARCHAR(150) NOT NULL,
    year_of_study INT NOT NULL,
    semester INT NOT NULL,
    credits INT NULL,
    programme_id INT NOT NULL,
    PRIMARY KEY (module_id),
    UNIQUE KEY uq_modules_module_code (module_code),
    KEY idx_modules_programme_id (programme_id),
    CONSTRAINT modules_ibfk_1
        FOREIGN KEY (programme_id)
        REFERENCES programmes (programme_id),
    CONSTRAINT chk_modules_year
        CHECK (year_of_study >= 1),
    CONSTRAINT chk_modules_semester
        CHECK (semester IN (1, 2)),
    CONSTRAINT chk_modules_credits
        CHECK (
            credits IS NULL
            OR credits > 0
        )
) ENGINE=InnoDB;

-- 6. STUDENT MODULE RESULTS
-- Stores student performance for individual modules

CREATE TABLE student_module_results (
    result_id INT NOT NULL AUTO_INCREMENT,
    student_id INT NOT NULL,
    module_id INT NOT NULL,
    academic_year VARCHAR(9) NOT NULL,
    continuous_assessment DECIMAL(5,2) NULL,
    examination_mark DECIMAL(5,2) NULL,
    final_mark DECIMAL(5,2) NULL,
    result VARCHAR(20) NULL,
    PRIMARY KEY (result_id),
    UNIQUE KEY uq_smr_student_module_year
        (student_id, module_id, academic_year),
    KEY idx_smr_module_id (module_id),
    CONSTRAINT student_module_results_ibfk_1
        FOREIGN KEY (student_id)
        REFERENCES students (student_id),
    CONSTRAINT student_module_results_ibfk_2
        FOREIGN KEY (module_id)
        REFERENCES modules (module_id),
    CONSTRAINT chk_smr_continuous_assessment
        CHECK (
            continuous_assessment IS NULL
            OR continuous_assessment BETWEEN 0 AND 100
        ),
    CONSTRAINT chk_smr_examination_mark
        CHECK (
            examination_mark IS NULL
            OR examination_mark BETWEEN 0 AND 100
        ),
    CONSTRAINT chk_smr_final_mark
        CHECK (
            final_mark IS NULL
            OR final_mark BETWEEN 0 AND 100
        )
) ENGINE=InnoDB;

-- 7. PREREQUISITES
-- Defines prerequisite relationships between modules

CREATE TABLE prerequisites (
    prerequisite_id INT NOT NULL AUTO_INCREMENT,
    module_id INT NOT NULL,
    prerequisite_module_id INT NOT NULL,
    PRIMARY KEY (prerequisite_id),
    UNIQUE KEY uq_prereq_module_pair
        (module_id, prerequisite_module_id),
    KEY idx_prereq_prerequisite_module
        (prerequisite_module_id),
    CONSTRAINT prerequisites_ibfk_1
        FOREIGN KEY (module_id)
        REFERENCES modules (module_id),
    CONSTRAINT prerequisites_ibfk_2
        FOREIGN KEY (prerequisite_module_id)
        REFERENCES modules (module_id),
    CONSTRAINT chk_prerequisite_not_self
        CHECK (module_id <> prerequisite_module_id)
) ENGINE=InnoDB;

-- 8. CO-REQUISITES
-- Defines co-requisite relationships between modules

CREATE TABLE co_requisites (
    co_requisite_id INT NOT NULL AUTO_INCREMENT,
    module_id INT NOT NULL,
    co_requisite_module_id INT NOT NULL,
    PRIMARY KEY (co_requisite_id),
    UNIQUE KEY uq_coreq_module_pair
        (module_id, co_requisite_module_id),
    KEY idx_coreq_module_id
        (co_requisite_module_id),
    CONSTRAINT co_requisites_ibfk_1
        FOREIGN KEY (module_id)
        REFERENCES modules (module_id),
    CONSTRAINT co_requisites_ibfk_2
        FOREIGN KEY (co_requisite_module_id)
        REFERENCES modules (module_id),
    CONSTRAINT chk_corequisite_not_self
        CHECK (module_id <> co_requisite_module_id)
) ENGINE=InnoDB;

-- 9. RISK PREDICTIONS
-- Stores experimental ML academic-risk classifications
-- based on synthetic student information

CREATE TABLE risk_predictions (
    prediction_id INT NOT NULL AUTO_INCREMENT,
    student_id INT NOT NULL,
    risk_level VARCHAR(20) NOT NULL,
    -- Probability stored between 0 and 1
    -- Example: 0.8750 = 87.50%
    prediction_probability DECIMAL(5,4) NULL,
    model_name VARCHAR(100) NULL,
    prediction_date DATE NOT NULL,
    PRIMARY KEY (prediction_id),
    KEY idx_risk_student_id (student_id),
    CONSTRAINT risk_predictions_ibfk_1
        FOREIGN KEY (student_id)
        REFERENCES students (student_id),
    CONSTRAINT chk_risk_probability
        CHECK (
            prediction_probability IS NULL
            OR prediction_probability BETWEEN 0 AND 1
        ),
    CONSTRAINT chk_risk_level
        CHECK (
            risk_level IN (
                'Low',
                'Medium',
                'High'
            )
        )
) ENGINE=InnoDB;

-- 10. ATTENDANCE
-- Stores attendance information associated with a
-- student's module result

CREATE TABLE attendance (
    attendance_id INT NOT NULL AUTO_INCREMENT,
    result_id INT NOT NULL,
    attendance_percentage DECIMAL(5,2) NOT NULL,
    PRIMARY KEY (attendance_id),
    UNIQUE KEY uq_attendance_result_id (result_id),
    CONSTRAINT attendance_ibfk_1
        FOREIGN KEY (result_id)
        REFERENCES student_module_results (result_id),
    CONSTRAINT chk_attendance_percentage
        CHECK (attendance_percentage BETWEEN 0 AND 100)
) ENGINE=InnoDB;

-- 11. ASSESSMENTS
-- Stores individual assessment information associated
-- with student module results

CREATE TABLE assessments (
    assessment_id INT NOT NULL AUTO_INCREMENT,
    result_id INT NOT NULL,
    assessment_type VARCHAR(30) NOT NULL,
    mark DECIMAL(5,2) NOT NULL,
    weight DECIMAL(5,2) NULL,
    PRIMARY KEY (assessment_id),
    KEY idx_assessments_result_id (result_id),
    CONSTRAINT assessments_ibfk_1
        FOREIGN KEY (result_id)
        REFERENCES student_module_results (result_id),
    CONSTRAINT chk_assessment_mark
        CHECK (mark BETWEEN 0 AND 100),
    CONSTRAINT chk_assessment_weight
        CHECK (weight IS NULL
            OR weight BETWEEN 0 AND 100)
) ENGINE=InnoDB;

-- RE-ENABLE FOREIGN KEY CHECKING

SET FOREIGN_KEY_CHECKS = 1;