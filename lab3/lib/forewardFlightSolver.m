function sol = forewardFlightSolver(hSol,helicopter, conf, Nt)

sol = struct();

sol.TipVelocity = helicopter.Radius*conf.Omega;

dPsi = 2*pi / Nt;
Psi = -dPsi;
N = length(helicopter.Mesh());
dr = helicopter.dR/helicopter.Radius;

%Pradtl deficiency model --> sum dct up to index
index = floor(0.97*N);

ITMAX = 1000;
TOL = 1e-6;
ITMAX_IN = 5;

mu = conf.ForewardVelocity/(helicopter.Radius*conf.Omega);

sol.InflowRatio = zeros(Nt,N);
sol.CT = zeros(Nt,N);

for i = 1:1:Nt 
    Psi = Psi + dPsi;
    
    for j = 1:1:N
        
        l_old = hSol.InflowRatio(j);
        it = 0;
        err = TOL + 1;
        r = helicopter.Mesh(j)/helicopter.Radius;

        while (it<ITMAX) && (err>TOL)
            it = it+1;
            
            %compute adimensional velocities
            vt = r+mu*sin(Psi)*cos(conf.AlfaShaft);
            vp = l_old + mu*sin(conf.AlfaShaft) + mu*cos(conf.AlfaShaft)*cos(Psi)*sin(conf.Flap);
            v = sqrt(vp^2 + vt^2);
            
            %Mach Number
            M = conf.Omega*helicopter.Radius*v/conf.SpeedOfSound;
            
            %Induced Angle
            phi = atan(vp/vt);
            
            %compute theta
            theta = conf.AngleOfAttack - conf.Theta1s*sin(Psi) - conf.Theta1c*cos(Psi);
            alfa = theta - phi;
            
            %aerodynamic data
            [cl,cd,~] = cpcrcm(alfa,M);
            
            %CT
            ct = real(helicopter.Solidity*0.5*(cos(phi)*cl -sin(phi)*cd)*v^2);
            
            %enter the inner loop
            l_new1 = l_old;
            it_in = 0;
            err_in = TOL+1;
            while (it_in < ITMAX_IN) && (err_in > TOL)
                it_in = it_in+1;
                l_new = (ct/2)*(1+1.2*r*cos(Psi))/sqrt((mu*cos(conf.AlfaShaft))^2 + (mu*sin(conf.AlfaShaft)+l_new1)^2);
                err_in = abs(l_new - l_new1);
                l_new1 = l_new;
            end
            
            err = abs(l_new - l_old);
            l_old = l_old + 0.01*(l_new-l_old);
        end
        sol.InflowRatio(i,j)=l_new;
        sol.CT(i,j) = ct;
    end
end

sol.ThrustCoefficientMean = mean(sol.CT,1);
sol.InflowRatioMean = mean(sol.InflowRatio,1);


end

