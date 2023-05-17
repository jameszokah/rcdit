# Rcdit

## RCDit Taxi App: Flutter-based Ride-Hailing Solution with Node.js Backend

RCDit is a cutting-edge, user-friendly taxi application designed to revolutionize the way people commute and access transportation services. Built with Flutter, a popular cross-platform development framework, RC-Dit ensures a seamless experience for both passengers and drivers. The app employs a robust Node.js backend, providing a reliable and scalable infrastructure to support its operations. 

## Understand this workspace

Run `npx nx graph` to see a diagram of the dependencies of the projects.

### To move into the rcdit rider/passenger app of the projects.
Run `cd ./apps/rcdit-rider`

### To previw passenger app
Run `flutter run `

### Now to run the Driver app

### move into the rcdit driver app of the projects.
Run `cd ./apps/rcdit-driver`

### To previw Driver app
Run `flutter run `


## For both Passengr and Driver app to run efficiently, you will need to run the sever first

### move into the rcdit server app of the projects.
Run `cd ./apps/rcdit-server`

### And start the server
Run `npx nx serve rcdit-server`


### Key Features:

User-Friendly Interface: RC-Dit boasts an intuitive and visually appealing interface, making it effortless for users to book rides and navigate through the application's various features.

Ride Booking: Passengers can easily request a ride by specifying their current location and desired destination. They can also choose from a range of available vehicle options such as economy cars, sedans, or SUVs.

Real-Time Tracking: RC-Dit offers real-time ride tracking, allowing passengers to monitor their driver's location and estimated time of arrival. This feature enhances safety and provides transparency throughout the journey.

Fare Estimation: Prior to confirming a ride, users can obtain a fare estimate based on the distance and chosen vehicle category. This functionality enables passengers to make informed decisions about their transportation options.

Multiple Payment Options: RC-Dit supports various payment methods, including credit/debit cards, digital wallets, and cash payments. Users can securely store their payment details and complete transactions with ease.

Driver Dispatch and Management: The app's Node.js backend efficiently handles driver dispatch and management. It ensures that drivers receive ride requests promptly and matches them with passengers based on their location and availability.

Driver Ratings and Reviews: Passengers can rate and provide feedback on their ride experience, promoting accountability and maintaining service quality standards. This feedback loop helps improve the overall user experience.

Admin Dashboard: RC-Dit includes a powerful admin dashboard that enables administrators to manage and monitor the entire system. They can track ride statistics, manage drivers and vehicles, and handle customer support efficiently.

Multilingual and Multi-Currency Support: To cater to a diverse user base, RC-Dit supports multiple languages and currencies. Users can easily switch between languages and view fares in their preferred currency.

Advanced Security Measures: RC-Dit prioritizes user safety by implementing stringent security measures. User data is encrypted and protected, and drivers undergo a rigorous verification process before joining the platform.

RC-Dit represents a robust and reliable taxi app solution that combines the versatility of Flutter with the scalability and performance of Node.js. With its seamless user experience, real-time tracking, and advanced features, RC-Dit sets a new standard in the world of ride-hailing applications, ensuring hassle-free and efficient transportation for all.


## Remote caching

Run `npx nx connect-to-nx-cloud` to enable [remote caching](https://nx.app) and make CI faster.

## Further help

Visit the [Documentation](https://github.com/jameszokah/rcdit) to learn more.
