import Link from "next/link";

export default function HelpPage() {
  return <main className="help-page">
    <div className="help-wrap">
      <Link className="help-back" href="/">← Retour à Boralog</Link>
      <header className="help-header">
        <p className="eyebrow">AIDE</p>
        <h1>Comment fonctionne Boralog ?</h1>
        <p>Boralog rassemble au même endroit les informations professionnelles utiles à un spectacle, un projet ou une date.</p>
        <p>Une information importante ne devrait pas avoir à être saisie plusieurs fois ni rester perdue dans les messages d’une seule personne.</p>
      </header>

      <section className="help-section">
        <h2>Les cinq espaces du quotidien</h2>
        <div className="help-grid">
          <article><h3>Aujourd’hui</h3><p>Montre ce qui demande votre attention maintenant : une information manquante, une réponse attendue, un changement à vérifier ou une prochaine échéance.</p></article>
          <article><h3>Messages</h3><p>C’est l’espace de communication professionnelle Boralog. Un message utile peut ensuite servir à organiser le travail, au lieu de rester perdu dans une conversation.</p></article>
          <article><h3>Projets</h3><p>Permet de retrouver les spectacles, leurs dates et les informations qui leur sont liées.</p></article>
          <article><h3>Recherche</h3><p>Permet de retrouver une information sans devoir se souvenir exactement de l’endroit où elle a été rangée.</p></article>
          <article><h3>Moi</h3><p>Correspond au compte de la personne connectée : son identité professionnelle, ses structures, ses rôles et, lorsque ces fonctions seront disponibles, ses préférences.</p></article>
        </div>
      </section>

      <section className="help-section help-date">
        <h2>Une date rassemble ce qui est utile</h2>
        <p>Une date se complète progressivement. Elle peut rassembler les horaires, l’équipe, le transport, l’hébergement, la technique, les documents, les tâches et les conversations, selon les besoins.</p>
      </section>

      <section className="help-section help-example">
        <h2>Un exemple simple</h2>
        <p>Léa apprend que le train de Paul arrive finalement à 18 h 12.</p>
        <p>L’information est mise à jour dans Boralog.</p>
        <p>Les personnes qui ont besoin de connaître cette nouvelle heure peuvent alors retrouver la bonne information au même endroit.</p>
        <strong>Une information → une mise à jour → les bonnes personnes retrouvent la bonne information.</strong>
      </section>

      <section className="help-section">
        <h2>Qui voit quoi ?</h2>
        <p>Tout le monde ne voit pas forcément les mêmes informations.</p>
        <p>L’accès dépend de la structure, du projet, du rôle de la personne et des autorisations qui lui ont été données.</p>
      </section>

      <section className="help-section">
        <h2>Votre espace</h2>
        <p>L’écran qui commence par « Bonjour [prénom] » correspond à l’espace de la personne actuellement connectée.</p>
        <p>Dans la version de démonstration actuelle, « Marion » est seulement un prénom fictif. Il ne représente pas une identité fixe de Boralog.</p>
      </section>

      <Link className="help-return" href="/">Retour à Boralog</Link>
    </div>
  </main>;
}
