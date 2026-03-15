package com.cityvoice.report.repository;

import com.cityvoice.report.entity.Report;
import com.cityvoice.report.enums.PriorityLevel;
import com.cityvoice.report.enums.ReportStatus;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Composable Specifications for dynamic multi-criteria report filtering.
 * Used by the staff-facing GET /reports endpoint.
 */
public class ReportSpecification {

    private ReportSpecification() {
    }

    /**
     * Builds a composite Specification from the provided filter values.
     * Any null parameter is silently ignored (not added as a predicate).
     */
    public static Specification<Report> buildFilter(
            ReportStatus status,
            PriorityLevel priority,
            UUID assignedToId,
            Integer categoryId) {

        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (status != null) {
                predicates.add(cb.equal(root.get("currentStatus"), status));
            }
            if (priority != null) {
                predicates.add(cb.equal(root.get("priority"), priority));
            }
            if (assignedToId != null) {
                predicates.add(cb.equal(root.get("assignedTo").get("id"), assignedToId));
            }
            if (categoryId != null) {
                predicates.add(cb.equal(root.get("category").get("id"), categoryId));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }
}
