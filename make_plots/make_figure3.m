%Plot example numerical solutions with and width a pyncocline in linear
%geometry. We plot u, d, \delta p and M = U\delta T
%% Preliminaries
clear; close all
numplot = 1;
addpath('Auxillary_functions')
figpref(4) %set plot defaults
cmap = [74, 67, 176]/255; %plot colours
dlc = [0.5, 0.5, 0.5]; %dashed line color

%% plot positions
width = 0.19;
ncols = 4;
colgap = 0.02;
rowgap = 0.1;
startx = (1 -width*ncols - (ncols-1)*colgap)/2;
starty = 0.07;
height = 0.4;
positions = zeros(4, ncols, 2);
for p = 1:2
    for q = 1:ncols
        positions(:,q,p) = [startx + (q-1)*colgap + (q-1)*width, starty + (p-1)*rowgap+ (p-1)*height, width, height];
    end
end
ps = positions;
ps(:,:,1) = positions(:,:,2);
ps(:,:,2) = positions(:,:,1);
positions = ps;
%% Parameters and bathymetry
run parameters %get dimensional parameters (be careful with global variable names)

% pycnocline position
x0      = 0.2;      % position of the thermocline (dimensionless)
Z0      = x0*l0;    %dimensional position of the pycnocline (Z coords)

%dimensionless parameters
eps1 = E0*alpha/Cd;
eps2 = E0*alpha/St;
eps3 = tau/(L/c);
eps4 = (S0 - S1)/2/S0;
eps5 = E0/2;
delta = lt/l0;
Pb = (L/c)/tau * (S0 - S1) /2 / S0 *( 1- bt*(T0 - T1)/bs / (S0 - S1));
Pt = (T0 - T1) / 2 / tau; %or Pt = (T0 - T1 + lambda1*(S0 - S1) / 2 / tau; %
kappa = (S0 + S1)/2 / S0 - bt*(L/c)/ bs / S0;
%Xmax = abs(zgl)/l0; %depth corresponding to ice shelf draft
Xmax = 1.2; %sets maximum depth to include
k2 = eps2/eps1;

%check supercritical near base:
if  Cd/alpha > 1
    warning('plume is subcritical near the base, may experience numerical instability')
end

% problem scales
d_scale         = E0*l0;
u_scale         = sqrt(bs*S0*g*l0*tau*E0*alpha/(L/c) / Cd);
delta_rho_scale = rho0*bs*S0;

%% Linear Ice shelf draft
zbF = @(X) X;
dzbF = @(X) 1 + 0*X;
d2zbF = @(X) 0 + 0*X;
d3zbF = @(X) 0 + 0*X;

xb = linspace(0,Xmax,1000); %bathymetry grid points
zb = zbF(xb);    %ice draft at grid points
%% Numerical solution of full equations
%solve the equations
i = 1;
figure(1);clf;
region1y = [0, 0, 0.15, 0.15]; %y co-ordinates of region 1 shaed box
region2y = [0.15, 0.15, 0.25, 0.25];
region3y = [0.25, 0.25, 0.5, 0.5];
region4y = [0.5, 0.5, 0.552, 0.552];

for X0 = [l0, x0] %first loop sets pycnocline very high, i.e. as if not there
    %solve the plume equations and return a solution structure
    tic; sol = GetPlume(eps1,eps2, eps3,eps4,delta, Pb, Pt, kappa, X0,zbF,dzbF, Xmax); toc
    sols{i} = sol;
    count = 1;
    
    %evaluate on a regular grid
    x = sol.x;
    x = linspace(0,x(end),1000);
    z = x*alpha;
    Y = deval(sol,x);
    d = Y(1,:);
    u = Y(2,:);
    delta_rho = Y(3,:);
    delta_T = Y(4,:); %dimensionless temperature
    Q = u.*d;
    
    %%%%%%Thickness%%%%%%%
    subplot('Position', positions(:,count,i)); hold on; box on
    if i ==2
        fill([0,1,1,0],region1y, 'b', 'FaceAlpha', 0.1, 'linestyle', 'none');
        fill([0,1,1,0],region2y, 'b', 'FaceAlpha', 0.2, 'linestyle', 'none');
        fill([0,1,1,0],region3y, 'b', 'FaceAlpha', 0.3, 'linestyle', 'none');
        fill([0,1,1,0],region4y, 'b', 'FaceAlpha', 0.4, 'linestyle', 'none');
    end
    plot(d,x,'color', cmap, 'linewidth', 3);
    xlim([0,1])
    ylabel('$X$', 'interpreter', 'latex')
    xlabel('$D$', 'interpreter', 'latex')
    ax = gca; xl = ax.XLim;
    plot(xl, x(end)*[1,1], '--', 'color', dlc); %add dashed x-stop line
    xlim(xl); %reset xlim in case previous line messes it up
    count = count + 1;
    if i == 1
        plot(xl, abs(zgl/l0)*[1,1], ':', 'color', dlc);
        txa = text(-0.3, 1.2, '(a)', 'FontSize', 16, 'interpreter', 'latex');
        txastop = text(0.05, 1.13, '$X = X_{\mathrm{stop}} \approx 1.1$', 'FontSize', 14, 'interpreter', 'latex');
        txax0 = text(0.69, 0.375, '$Z = |Z_{gl}| $', 'FontSize', 14, 'interpreter', 'latex');
        
    else
        plot(xl, abs(zgl/l0)*[1,1], ':', 'color', dlc);
        txax0 = text(0.69, 0.35, '$Z = |Z_{gl}| $', 'FontSize', 14, 'interpreter', 'latex');
        plot(xl,X0*[1,1],'-.', 'color', dlc);
        txb = text(-0.3, 0.6, '(b)', 'FontSize', 16, 'interpreter', 'latex');
        txbx0 = text(0.55, 0.22, '$X = X_p = 0.2$', 'FontSize', 14, 'interpreter', 'latex');
        txbstop = text(0.05, 0.572, '$X = X_{\mathrm{stop}} \approx 0.55$', 'FontSize', 14, 'interpreter', 'latex');
    end
    
    
    %%%%%Velocity%%%%%
    subplot('Position', positions(:,count,i)); hold on; box on
    %layers
    if i ==2
        fill([0,0.3,0.3,0],region1y, 'b', 'FaceAlpha', 0.1, 'linestyle', 'none');
        fill([0,0.3,0.3,0],region2y, 'b', 'FaceAlpha', 0.2, 'linestyle', 'none');
        fill([0,0.3,0.3,0],region3y, 'b', 'FaceAlpha', 0.3, 'linestyle', 'none');
        fill([0,0.3,0.3,0],region4y, 'b', 'FaceAlpha', 0.4, 'linestyle', 'none');
    end
    plot(u,x,'color', cmap, 'linewidth', 3);
    %ylabel('x')
    xlabel('$U$', 'interpreter', 'latex')
    if i == 2; xlim([0, 0.3]); end
    ax = gca; xl = ax.XLim;
    plot(xl, x(end)*[1,1], '--', 'color', dlc); %add dashed x-stop line
    xlim(xl); %reset xlim in case previous line messes it up
    yticks([])
    count = count + 1;
    plot(xl, abs(zgl/l0)*[1,1], ':', 'color', dlc);
    if i == 2
        plot(xl,X0*[1,1],'-.', 'color', dlc);
    end
    
    %%%%%Buoyancy deficit%%%%%%
    subplot('Position', positions(:,count,i)); hold on; box on
    if i ==2
        fill([-0.25,1,1,-0.25],region1y, 'b', 'FaceAlpha', 0.1, 'linestyle', 'none');
        fill([-0.25,1,1,-0.25],region2y, 'b', 'FaceAlpha', 0.2, 'linestyle', 'none');
        fill([-0.25,1,1,-0.25],region3y, 'b', 'FaceAlpha', 0.3, 'linestyle', 'none');
        fill([-0.25,1,1,-0.25],region4y, 'b', 'FaceAlpha', 0.4, 'linestyle', 'none');
    end
    plot(delta_rho,x,'color', cmap, 'linewidth', 3);
    %ylabel('x')
    xlabel('$\Delta \rho$', 'interpreter', 'latex')
    xlim([-0.25, 1])
    ax = gca; xl = ax.XLim;
    plot(xl, x(end)*[1,1], '--', 'color', dlc); %add dashed x-stop line
    xlim(xl); %reset xlim in case previous line messes it up
    yticks([])
    count = count + 1;
    plot(xl, abs(zgl/l0)*[1,1], ':', 'color', dlc);
    if i == 2
        plot(xl,X0*[1,1],'-.', 'color', dlc);
        tx1 = text(-.2, 0.07, '$1$', 'FontSize', 16, 'interpreter', 'latex');
        tx2 = text(-.2, 0.22,  '$2$', 'FontSize', 16, 'interpreter', 'latex');
        tx3 = text(-.2, 0.37, '$3$', 'FontSize', 16, 'interpreter', 'latex');
        tx4 = text(-.2, 0.52,  '$4$', 'FontSize', 16, 'interpreter', 'latex');
    end
    
    %%%% Melt Rate %%%%
    subplot('Position', positions(:,count,i)); hold on; box on
    if i ==2
        fill([-0.1,.2,.2,-0.1],region1y, 'b', 'FaceAlpha', 0.1, 'linestyle', 'none');
        fill([-0.1,.2,.2,-0.1],region2y, 'b', 'FaceAlpha', 0.2, 'linestyle', 'none');
        fill([-0.1,.2,.2,-0.1],region3y, 'b', 'FaceAlpha', 0.3, 'linestyle', 'none');
        fill([-0.1,.2,.2,-0.1],region4y, 'b', 'FaceAlpha', 0.4, 'linestyle', 'none');
    end
    plot([0,0], [0,1.2 - 0.6*(i-1)], 'color', dlc, 'linewidth', 1) %vertical line thru zero: where does refreezing take over
    plot(delta_T.*u,x,'color', cmap, 'linewidth', 3);
    %ylabel('x')
    xlabel('$M = U \Delta T$','interpreter', 'latex')
    if i == 2; xlim([-0.1, .2]); else;   xlim([-0.3, .2]); end
    ax = gca; xl = ax.XLim;
    plot(xl, x(end)*[1,1], '--', 'color', dlc); %add dashed x-stop line
    xlim(xl); %reset xlim in case previous line messes it up
    yticks([])
    count = count + 1;
    plot(xl, abs(zgl/l0)*[1,1], ':', 'color', dlc);
    if i == 2 
        plot(xl,X0*[1,1],'-.', 'color', dlc);
    end
    i = i + 1;
end


%figure sizing
fig = gcf;
fig.Position(3:4) =[1067 650];

%saving
% saveas(gcf, 'plots/figure3.png')