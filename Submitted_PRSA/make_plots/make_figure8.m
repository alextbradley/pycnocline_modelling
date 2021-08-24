%make figure 8 of the manuscript.
%Comparison between melt rate parametrizations and numerical solutions for
%four different ice shelf basal topographies as follows:
%(a) idealized quadratic profile
%(b) idealized sinusoidal profile
%(c) idealized piecewise linear profile
%(d) representative profile
%% Preliminaries
clear
%clc

colmap = [74, 67, 176;
    81, 146, 246;
    244, 177, 115
    119,205, 156]/255;
addpath('Auxillary_functions')

%% Idealized geometries
%Using standard parameters
run Parameters/typical_parameters %get dimensional parameters (be careful with global variable names)
%lt = 40
%variable scales:
D_scale         = E0*l0;
U_scale         = sqrt(bs*S0*g*l0*tau*E0*alpha/(L/c) / Cd);
delta_rho_scale = rho0*bs*S0*tau/(L/c);
delta_T_scale   = E0 *alpha * tau/St;
X_scale         = tau/lambda3 /alpha;

M0 = St/(L/c);    %melt rate prefactor
%pycnocline positions
Z0_lo  = 260;
Z0_hi  = 780;

%dimensionless parameters
eps1 = E0*alpha/Cd;
eps2 = E0*alpha/St;
eps3 = tau/(L/c);
eps4 = (S0 - S1)/2/S0;
delta = lt/l0;
Pb = (L/c)/tau * (S0 - S1) /2 / S0 *( 1- bt*(T0 - T1)/bs / (S0 - S1));
Pt = (T0 - T1) / 2 / tau; %or Pt = (T0 - T1 + lambda1*(S0 - S1) / 2 / tau; %
lambda = (S0 + S1)/2 / S0 - bt*(L/c)/ bs / S0;
%% Ice Drafts:
N = 1e3; %Number of pts in the draft
Xb = zeros(3, N);
Zb = zeros(3, N); %initialize arrays
dZb= zeros(3, N);

% Geometry 1: gently decreasing
Xb(1,:) = linspace(eps, abs(zgl)/alpha*2, N);  %l0/alpha is X lengthscale (need to run to longer because takes longer to reach zgl with negative curvature)
p  = 0.45; %controls strength of curvature
Zb(1,:) = l0*(Xb(1,:)/X_scale - p* (Xb(1,:)/X_scale).^2);
dZb(1,:) = l0*(1/X_scale - 2*p* (Xb(1,:)/X_scale^2));

% Geometry 2: sinusoidal
Xb(2,:) = linspace(eps, abs(zgl)/alpha, N);  %l0/alpha is X lengthscale
amp = 30; %amplitude of sin
per = 1e5; %period of sin
Zb(2,:) = alpha*Xb(2,:) + amp*sin(2*pi*Xb(2,:)/per);
dZb(2,:) = alpha*ones(size(Xb(2,:))) + (amp*2*pi/per)*cos(2*pi*Xb(2,:)/per);

% Geometry 3: piecewise linear
%change slope in second half by a factor of slope2
Xb(3,:) = linspace(eps, abs(zgl)/alpha, N);  %l0/alpha is X lengthscale
lx = length(Xb);
Xb_cross = Xb(3,floor(lx/3)); %where the jump occurs
slope2 = 2;
jump = slope2*alpha*Xb(3,floor(lx/3) + 1) - alpha*Xb(3,floor(lx/3)); %jump incurred if we dont shift second half
Zb(3,:) = [alpha*Xb(3,1:floor(lx/3)), slope2*alpha*Xb(3,floor(lx/3) + 1: end) - jump];
dZb(3,:) = [alpha*ones(1,floor(lx/3)), slope2*alpha*ones(1,lx -floor(lx/3))] ;

Xb(4,:) = linspace(eps, abs(zgl)/alpha*2, N);  %l0/alpha is X lengthscale (need to run to longer because takes longer to reach zgl with negative curvature)
p  = 0.45; %controls strength of curvature
quadterm = 4.2;
cubicterm = 0.2;
Zb(4,:) = l0*(Xb(4,:)/X_scale - quadterm* (Xb(4,:)/X_scale).^2 + cubicterm*(4 * Xb(4,:)/X_scale).^3);
dZb(4,:) = l0*(1/X_scale - 2*quadterm* (Xb(1,:)/X_scale^2) + cubicterm*3*4 * (4 * Xb(4,:)).^2 / X_scale^3);

% Store as anonymous functions for the constructed melt rate
zbFs = {@(x) x - p*x.^2;... %quadratic
    @(x) x + (amp/l0)*sin(2*pi*x*X_scale/per);... %sinusoidal
    @(x) (x.*(x <= Xb_cross/X_scale) + (slope2*x - jump/l0).*(x > Xb_cross/X_scale)); %piecewise linear
    @(x)  x - quadterm* x.^2 + cubicterm*(4*x).^3}; %smooth varying with lump in middle and ramp to end
dzbFs = {@(x) 1 - 2*p*x; ...
    @(x) 1 + (amp/l0)*(2*pi*X_scale/per) *cos(2*pi*x*X_scale/per) ;...
    @(x) (1*(x <= Xb_cross/X_scale) + slope2*(x > Xb_cross/X_scale));
    @(x) 1 - 2*quadterm*x + cubicterm*3*4*(4*x).^2};

d2zbFs = {@(x)  - 2*p; ...
    @(x) -(amp/l0)*(2*pi*X_scale/per)^2 *sin(2*pi*x*X_scale/per) ;...
    @(x) 0 + 0*x;
    @(x) -2.4 + cubicterm*3*4*4*2*(4*x)};

d3zbFs = {@(x) 0 + 0*x; ...
    @(x) -(amp/l0)*(2*pi*X_scale/per)^3 *cos(2*pi*x*X_scale/per) ;...
    @(x) 0 + 0*x;
    @(x) cubicterm*3*4*4*2*4 + 0*x};

figure(1);clf;
%% Loop over each bathymetry
pltcnt = 1;
for i = [1,4,2,3]
    count = 1;
    % figure(i); clf;

     
    for Z0 = [Z0_lo, Z0_hi]
        sol =  GetPlumeDimensional(Ti, Si, T0, T1, S0, S1, Z0, rho0, zgl, L, ci,lt,g,Cd,...
                                      c, bs, bt, E0, St, lambda1, lambda2, lambda3, tau,...
                                      Xb(i,:), Zb(i,:), dZb(i,:));
        %process
        %evaluate on Xb grid pts
        %find where draft pts within solution interval (should include zero)
        idx = ((Xb(i,:) > min(sol.x)) + (Xb(i,:) < max(sol.x)))>1;
        
        X = Xb(i,idx);
        Y = deval(sol, Xb(i,idx));
        Z = X*alpha;
        U = Y(2,:);
        delta_T = Y(4,:); %dimensionless temperature
        Melt_rate = M0*U.*delta_T*secs_per_yr; %melt rate in metres per year
        
        %add Lazeroms/constant draft
        xlz = linspace(0,abs(zgl))/alpha/X_scale;
        Zlz = linspace(0,abs(zgl));
        Q_lz = zeros(1,length(xlz)); %lower case x is dimensionless
        U_lz = zeros(1,length(xlz));  %initialize
        
        integrand = @(x) lambda^(1/3).*(1 - x).^(1/3); %integrand used in analytic solution below thermocline
        for j = 1:length(xlz)
            Q_lz(j) =  (2/3 *integral(integrand, 0, xlz(j)))^(3/2);
            U_lz(j) = lambda^(1/3)  * (1 - xlz(j))^(1/3) * ...
                (2/3 *integral(integrand, 0, xlz(j)))^(1/2); %u = Q'/zb' in this region
        end
        delta_T_lz = (-Q_lz + U_lz.*(1-xlz))./U_lz;
        M_Lzrms_ND = delta_T_lz.*U_lz;
        M_Lzrms    = M0 * U_scale * delta_T_scale * M_Lzrms_ND * secs_per_yr;
        % plot(M_Lzrms, Z + zgl, 'k--');
        
        %add Lazeroms (ad-hoc adjustment)
        dzbF = dzbFs{i};
        Tave = (T0 + T1)/2;
        Save = (S0 + S1)/2;
        tauLz = Tave - (lambda1*Save + lambda2 + lambda3*zgl);
        U_scale_adhoc         = sqrt(bs*(S0+S1)/2*g*l0*tau*E0*(dzbF(xlz)*alpha)/(L/c) / Cd); %extra factor of alpha because dzbF is non-dimensional
        delta_T_scale_adhoc   = E0 *(dzbF(xlz) *alpha) * tauLz/St;
        M_Lzrms_adhoc    = M0 * U_scale_adhoc .* delta_T_scale_adhoc .* M_Lzrms_ND * secs_per_yr;
        %plot(M_Lzrms_adhoc, Z + zgl, 'color', colmap(3,:), 'linewidth',3);
        
        %add constructed melt rate
        [M_AB,X_AB] = GetConstructedMeltRate(zbFs{i}, dzbFs{i}, d2zbFs{i}, d3zbFs{i},...
            Z0/l0, Pt, Pb, delta, lambda);
        
        %make plots
       
        if count == 1
            subplot(2,4,pltcnt); hold on
            plot([0, 0], [0, max(Z)] + zgl,'--', 'color', [1,1,1]*169/255);
            plot(Melt_rate, Z + zgl, 'color', colmap(1,:), 'linewidth', 3);
            plot(M_Lzrms_adhoc, Zlz + zgl, 'color', colmap(3,:), 'linewidth', 3);
            plot(M_AB * M0 * U_scale * delta_T_scale *secs_per_yr, X_AB*X_scale*alpha + zgl, 'color', colmap(4,:),'linewidth', 3)
            box on
            ylim([zgl, 0])
            pltcnt = pltcnt + 1;
            xlabel('melt rate (m/yr) ', 'interpreter', 'latex', 'FontSize', 16);
            ylabel('$Z + Z_{gl}$~(m)', 'interpreter', 'latex', 'FontSize', 16)
            ax = gca; ax.FontSize = 16;
            

        else
            subplot(2,4,pltcnt); hold on
            plot([0, 0], [0, max(Z)] + zgl,'--', 'color', [1,1,1]*169/255);
            plot(Melt_rate, Z + zgl, 'color', colmap(1,:), 'linewidth', 3);
            plot(M_Lzrms_adhoc, Zlz + zgl, 'color', colmap(3,:), 'linewidth', 3);
            plot(M_AB * M0 * U_scale * delta_T_scale *secs_per_yr, X_AB*X_scale*alpha + zgl, 'color', colmap(4,:),'linewidth', 3)
            box on
            ylim([zgl, 0])
            xlabel('melt rate (m/yr) ', 'interpreter', 'latex', 'FontSize', 16);
            ax = gca; ax.FontSize = 16;

               pltcnt = pltcnt + 1;
        end
        
       
        count = count + 1;
    end
%     fig = gcf; 
%     fig.Position(3:4) = [572 360];
end