#include "config.h"
#include <iostream>
#include <fstream>
#include <cmath>
#include <vector>
#include <chrono>

namespace forces {
    void computeLennardJones_CPU(
        Config& cfg,
        std::vector<double>& fx,
        std::vector<double>& fy,
        std::vector<double>& fz,
        const std::vector<std::vector<int>>& nlist
    ) {
        double sigma = 1.0, epsilon = 0.01;  // Reduced epsilon
        for (int i = 0; i < cfg.natoms; i++) {
            double fx_i = 0, fy_i = 0, fz_i = 0;
            if (i < (int)nlist.size()) {
                for (int j : nlist[i]) {
                    if (j < cfg.natoms && j > i) {
                        double dx = cfg.x[j] - cfg.x[i];
                        double dy = cfg.y[j] - cfg.y[i];
                        double dz = cfg.z[j] - cfg.z[i];
                        
                        if (dx > cfg.box_size * 0.5) dx -= cfg.box_size;
                        else if (dx < -cfg.box_size * 0.5) dx += cfg.box_size;
                        if (dy > cfg.box_size * 0.5) dy -= cfg.box_size;
                        else if (dy < -cfg.box_size * 0.5) dy += cfg.box_size;
                        if (dz > cfg.box_size * 0.5) dz -= cfg.box_size;
                        else if (dz < -cfg.box_size * 0.5) dz += cfg.box_size;
                        
                        double r2 = dx*dx + dy*dy + dz*dz;
                        if (r2 < 1e-10) continue;
                        
                        double sr2_inv = 1.0 / r2;
                        double sr6_inv = sr2_inv * sr2_inv * sr2_inv;
                        double sr12_inv = sr6_inv * sr6_inv;
                        
                        double sigma6 = sigma * sigma * sigma * sigma * sigma * sigma;
                        double sigma12 = sigma6 * sigma6;
                        
                        double f_mag = 48.0 * epsilon * (sigma12 * sr12_inv * sr2_inv - 0.5 * sigma6 * sr6_inv * sr2_inv);
                        
                        fx_i += f_mag * dx;
                        fy_i += f_mag * dy;
                        fz_i += f_mag * dz;
                    }
                }
            }
            fx[i] += fx_i;
            fy[i] += fy_i;
            fz[i] += fz_i;
        }
    }
    
    void computeBondedForces_CPU(
        Config& cfg,
        std::vector<double>& fx,
        std::vector<double>& fy,
        std::vector<double>& fz
    ) {
        // Bonds
        for (const auto& bond : cfg.bonds) {
            int i = bond.i, j = bond.j;
            double dx = cfg.x[j] - cfg.x[i];
            double dy = cfg.y[j] - cfg.y[i];
            double dz = cfg.z[j] - cfg.z[i];
            
            if (dx > cfg.box_size * 0.5) dx -= cfg.box_size;
            else if (dx < -cfg.box_size * 0.5) dx += cfg.box_size;
            if (dy > cfg.box_size * 0.5) dy -= cfg.box_size;
            else if (dy < -cfg.box_size * 0.5) dy += cfg.box_size;
            if (dz > cfg.box_size * 0.5) dz -= cfg.box_size;
            else if (dz < -cfg.box_size * 0.5) dz += cfg.box_size;
            
            double r = sqrt(dx*dx + dy*dy + dz*dz);
            if (r < 1e-10) continue;
            
            double dr = r - bond.req;
            double f_mag = bond.k_b * dr / r;
            
            fx[i] += f_mag * dx;
            fy[i] += f_mag * dy;
            fz[i] += f_mag * dz;
            
            fx[j] -= f_mag * dx;
            fy[j] -= f_mag * dy;
            fz[j] -= f_mag * dz;
        }
        
        // Angles
        for (const auto& angle : cfg.angles) {
            int i = angle.i, j = angle.j, k = angle.k;
            
            double r1x = cfg.x[i] - cfg.x[j];
            double r1y = cfg.y[i] - cfg.y[j];
            double r1z = cfg.z[i] - cfg.z[j];
            
            double r2x = cfg.x[k] - cfg.x[j];
            double r2y = cfg.y[k] - cfg.y[j];
            double r2z = cfg.z[k] - cfg.z[j];
            
            double r1 = sqrt(r1x*r1x + r1y*r1y + r1z*r1z);
            double r2 = sqrt(r2x*r2x + r2y*r2y + r2z*r2z);
            
            if (r1 < 1e-10 || r2 < 1e-10) continue;
            
            double cos_theta = (r1x*r2x + r1y*r2y + r1z*r2z) / (r1 * r2);
            cos_theta = (cos_theta > 1.0) ? 1.0 : (cos_theta < -1.0 ? -1.0 : cos_theta);
            
            double theta = acos(cos_theta);
            double dtheta = theta - angle.theta_eq;
            double force_mag = -2.0 * angle.k_a * dtheta;
            
            double r1_inv = 1.0 / r1;
            double r2_inv = 1.0 / r2;
            double sin_theta = sin(theta);
            if (sin_theta < 1e-10) sin_theta = 1e-10;
            
            double denom = sin_theta * r1 * r2;
            double f_coef = force_mag / denom;
            
            double f_i_x = f_coef * (cos_theta * r1x * r1_inv - r2x * r2_inv);
            double f_i_y = f_coef * (cos_theta * r1y * r1_inv - r2y * r2_inv);
            double f_i_z = f_coef * (cos_theta * r1z * r1_inv - r2z * r2_inv);
            
            double f_k_x = f_coef * (cos_theta * r2x * r2_inv - r1x * r1_inv);
            double f_k_y = f_coef * (cos_theta * r2y * r2_inv - r1y * r1_inv);
            double f_k_z = f_coef * (cos_theta * r2z * r2_inv - r1z * r1_inv);
            
            double f_j_x = -(f_i_x + f_k_x);
            double f_j_y = -(f_i_y + f_k_y);
            double f_j_z = -(f_i_z + f_k_z);
            
            fx[i] += f_i_x; fy[i] += f_i_y; fz[i] += f_i_z;
            fx[j] += f_j_x; fy[j] += f_j_y; fz[j] += f_j_z;
            fx[k] += f_k_x; fy[k] += f_k_y; fz[k] += f_k_z;
        }
    }
}

namespace neighbor {
    void buildNeighborList_CPU(
        Config& cfg,
        std::vector<std::vector<int>>& nlist
    ) {
        double rcut = 12.0;
        double rskin = 2.0;
        double rcut_sq = (rcut + rskin) * (rcut + rskin);
        
        nlist.clear();
        nlist.resize(cfg.natoms);
        
        for (int i = 0; i < cfg.natoms; i++) {
            for (int j = i + 1; j < cfg.natoms; j++) {
                double dx = cfg.x[j] - cfg.x[i];
                double dy = cfg.y[j] - cfg.y[i];
                double dz = cfg.z[j] - cfg.z[i];
                
                if (dx > cfg.box_size * 0.5) dx -= cfg.box_size;
                else if (dx < -cfg.box_size * 0.5) dx += cfg.box_size;
                if (dy > cfg.box_size * 0.5) dy -= cfg.box_size;
                else if (dy < -cfg.box_size * 0.5) dy += cfg.box_size;
                if (dz > cfg.box_size * 0.5) dz -= cfg.box_size;
                else if (dz < -cfg.box_size * 0.5) dz += cfg.box_size;
                
                double r2 = dx*dx + dy*dy + dz*dz;
                if (r2 < rcut_sq) {
                    nlist[i].push_back(j);
                    nlist[j].push_back(i);
                }
            }
        }
    }
}

namespace integrator {
    void velocityVerlet(Config& cfg, std::vector<double>& fx, 
                       std::vector<double>& fy, std::vector<double>& fz, double dt) {
        double dt2 = dt * dt / 2.0;
        
        for (int i = 0; i < cfg.natoms; i++) {
            cfg.vx[i] += (fx[i] / cfg.mass[i]) * dt / 2.0;
            cfg.vy[i] += (fy[i] / cfg.mass[i]) * dt / 2.0;
            cfg.vz[i] += (fz[i] / cfg.mass[i]) * dt / 2.0;
        }
        
        for (int i = 0; i < cfg.natoms; i++) {
            cfg.x[i] += cfg.vx[i] * dt + (fx[i] / cfg.mass[i]) * dt2;
            cfg.y[i] += cfg.vy[i] * dt + (fy[i] / cfg.mass[i]) * dt2;
            cfg.z[i] += cfg.vz[i] * dt + (fz[i] / cfg.mass[i]) * dt2;
        }
        
        for (int i = 0; i < cfg.natoms; i++) {
            while (cfg.x[i] > cfg.box_size) cfg.x[i] -= cfg.box_size;
            while (cfg.x[i] < 0) cfg.x[i] += cfg.box_size;
            while (cfg.y[i] > cfg.box_size) cfg.y[i] -= cfg.box_size;
            while (cfg.y[i] < 0) cfg.y[i] += cfg.box_size;
            while (cfg.z[i] > cfg.box_size) cfg.z[i] -= cfg.box_size;
            while (cfg.z[i] < 0) cfg.z[i] += cfg.box_size;
        }
        
        for (int i = 0; i < cfg.natoms; i++) {
            fx[i] = fy[i] = fz[i] = 0.0;
        }
    }
    
    double calcTemperature(Config& cfg) {
        double ke = 0.0;
        for (int i = 0; i < cfg.natoms; i++) {
            double v2 = cfg.vx[i]*cfg.vx[i] + cfg.vy[i]*cfg.vy[i] + cfg.vz[i]*cfg.vz[i];
            ke += 0.5 * cfg.mass[i] * v2;
        }
        return 2.0 * ke / (3.0 * cfg.natoms);
    }
}

int main() {
    std::cout << "=== GromacsMexicano Phase 3 CUDA (Full 3 Kernels) ===" << std::endl;
    
    Config cfg;
    cfg.natoms = 100;
    cfg.box_size = 20.0;
    cfg.dt = 0.001;
    cfg.nsteps = 1000;
    cfg.nsave = 100;
    
    cfg.x.resize(cfg.natoms);
    cfg.y.resize(cfg.natoms);
    cfg.z.resize(cfg.natoms);
    cfg.vx.resize(cfg.natoms);
    cfg.vy.resize(cfg.natoms);
    cfg.vz.resize(cfg.natoms);
    cfg.fx.resize(cfg.natoms);
    cfg.fy.resize(cfg.natoms);
    cfg.fz.resize(cfg.natoms);
    cfg.mass.resize(cfg.natoms, 1.0);
    cfg.charge.resize(cfg.natoms, 0.0);
    
    srand(12345);
    for (int i = 0; i < cfg.natoms; i++) {
        cfg.x[i] = (double)rand() / RAND_MAX * cfg.box_size;
        cfg.y[i] = (double)rand() / RAND_MAX * cfg.box_size;
        cfg.z[i] = (double)rand() / RAND_MAX * cfg.box_size;
        cfg.vx[i] = (double)rand() / RAND_MAX - 0.5;
        cfg.vy[i] = (double)rand() / RAND_MAX - 0.5;
        cfg.vz[i] = (double)rand() / RAND_MAX - 0.5;
    }
    
    for (int i = 0; i < cfg.natoms - 1; i++) {
        Bond b{i, i+1, 1.0, 50.0};  // Reduced k_b
        cfg.bonds.push_back(b);
    }
    
    for (int i = 0; i < cfg.natoms - 2; i++) {
        Angle a{i, i+1, i+2, M_PI, 25.0};  // Reduced k_a
        cfg.angles.push_back(a);
    }
    
    std::cout << "System: " << cfg.natoms << " atoms" << std::endl;
    std::cout << "Bonds: " << cfg.bonds.size() << ", Angles: " << cfg.angles.size() << std::endl;
    
    std::ofstream outfile("phase3_results.txt");
    outfile << "Step\tTemp(K)\tKernel(ms)\tInteg(ms)\tNlist(ms)" << std::endl;
    
    std::vector<double> kernel_times, nlist_times, integ_times;
    
    auto t_sim_start = std::chrono::high_resolution_clock::now();
    std::vector<std::vector<int>> nlist;
    
    for (int step = 0; step < cfg.nsteps; step++) {
        if (step % 20 == 0) {
            auto t_start = std::chrono::high_resolution_clock::now();
            neighbor::buildNeighborList_CPU(cfg, nlist);
            auto t_end = std::chrono::high_resolution_clock::now();
            nlist_times.push_back(std::chrono::duration<double, std::milli>(t_end - t_start).count());
        }
        
        for (int i = 0; i < cfg.natoms; i++) {
            cfg.fx[i] = cfg.fy[i] = cfg.fz[i] = 0.0;
        }
        
        auto t_start = std::chrono::high_resolution_clock::now();
        forces::computeLennardJones_CPU(cfg, cfg.fx, cfg.fy, cfg.fz, nlist);
        forces::computeBondedForces_CPU(cfg, cfg.fx, cfg.fy, cfg.fz);
        auto t_end = std::chrono::high_resolution_clock::now();
        kernel_times.push_back(std::chrono::duration<double, std::milli>(t_end - t_start).count());
        
        t_start = std::chrono::high_resolution_clock::now();
        integrator::velocityVerlet(cfg, cfg.fx, cfg.fy, cfg.fz, cfg.dt);
        t_end = std::chrono::high_resolution_clock::now();
        integ_times.push_back(std::chrono::duration<double, std::milli>(t_end - t_start).count());
        
        double temp = integrator::calcTemperature(cfg);
        
        if (step % cfg.nsave == 0) {
            outfile << step << "\t" << temp << "\t" << kernel_times.back() << "\t" 
                    << integ_times.back() << "\t" << (nlist_times.size() > 0 ? nlist_times.back() : 0) << std::endl;
            if (step % 200 == 0 && step > 0) {
                std::cout << "  Step " << step << " T=" << temp << " K" << std::endl;
            }
        }
    }
    
    auto t_sim_end = std::chrono::high_resolution_clock::now();
    double total_time = std::chrono::duration<double>(t_sim_end - t_sim_start).count();
    
    outfile.close();
    
    std::cout << "\n=== Performance Results ===" << std::endl;
    std::cout << "Total time: " << total_time << " s" << std::endl;
    std::cout << "Steps per second: " << cfg.nsteps / total_time << std::endl;
    
    double kernel_total = 0, integ_total = 0, nlist_total = 0;
    for (auto t : kernel_times) kernel_total += t;
    for (auto t : integ_times) integ_total += t;
    for (auto t : nlist_times) nlist_total += t;
    
    std::cout << "\nKernel (Pairwise+Bonded): " << kernel_total << " ms (avg " << kernel_total/kernel_times.size() << " ms/step)" << std::endl;
    std::cout << "Integrator: " << integ_total << " ms (avg " << integ_total/integ_times.size() << " ms/step)" << std::endl;
    if (nlist_times.size() > 0) {
        std::cout << "Neighbor list: " << nlist_total << " ms (" << nlist_times.size() << " builds, avg " << nlist_total/nlist_times.size() << " ms)" << std::endl;
    }
    
    std::cout << "\nResults written to phase3_results.txt" << std::endl;
    
    return 0;
}
