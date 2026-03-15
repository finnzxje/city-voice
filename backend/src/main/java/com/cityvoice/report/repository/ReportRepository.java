package com.cityvoice.report.repository;

import com.cityvoice.report.entity.Report;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ReportRepository extends JpaRepository<Report, UUID>, JpaSpecificationExecutor<Report> {
    List<Report> findAllByCitizenIdOrderByCreatedAtDesc(UUID citizenId);
}
