import { GetStaticPaths, GetStaticProps, NextPage } from "next";

type Post = {id: string, title: string}
const posts: Post[] = [{
    id: "1",
    title: "First post"
}];

export const getStaticPaths: GetStaticPaths = () => {
    return {
        paths: posts.map(({id}) => ({params: {id}})),
        fallback: false
    }
}

export const getStaticProps: GetStaticProps = ({params}) => {
    return {
        props: {
            data: posts.find(({id}) => id === params!.id),
            time: Date.now()
        }
    }
}

const Post: NextPage<{data: Post, time: number}> = ({data, time}) => (
    <article>
        <h1>Static Site Generation with dynamic routes</h1>
        <h2>Test 1:</h2>
        <p>This timestamp 👉 <b>{time}</b> should be when the `npx open-next build` was run, not when the page is refreshed. Hence, this time should not change on refresh.</p>
        <h2>Test 2:</h2>
        <p>This string 👉 &quot;{data.title}&quot; should be &quot;First post&quot;.</p>
        <h2>Test 3:</h2>
        <p>Check your browser&apos;s developer console. First request might show cache MISS on first load. Subsequent refreshes should shows cache HIT.</p>
    </article>
)

export default Post;