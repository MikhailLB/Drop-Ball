const supportPageUrl = 'https://gravittyrush.com/support.html';
const privacyPolicyPageUrl = 'https://gravittyrush.com/privacy-policy.html';

const leaderboardApiUrl = 'https://api.gravittyrush.com/v1/leaderboard';
const skinStoreApiUrl = 'https://api.gravittyrush.com/v1/skins/catalog';
const achievementsApiUrl = 'https://api.gravittyrush.com/v1/achievements';
const dailyChallengeUrl = 'https://api.gravittyrush.com/v1/daily-challenge';
const playerProfileUrl = 'https://api.gravittyrush.com/v1/player/profile';
const tournamentApiUrl = 'https://api.gravittyrush.com/v1/tournaments';

String buildLeaderboardUrl(String season) =>
    '$leaderboardApiUrl?season=$season';

String buildProfileUrl(String playerId) =>
    '$playerProfileUrl/$playerId';
